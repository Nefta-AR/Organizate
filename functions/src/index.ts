import * as admin from 'firebase-admin';
import * as functionsV1 from 'firebase-functions/v1';
import * as httpsFn from 'firebase-functions/v2/https';
import * as params from 'firebase-functions/params';
import { TextToSpeechClient, protos } from '@google-cloud/text-to-speech';

admin.initializeApp();

// ─────────────────────────────────────────────────────────────
// CONFIGURACIÓN
// ─────────────────────────────────────────────────────────────

const GEMINI_API_KEY = params.defineSecret('GEMINI_API_KEY');

const GEMINI_MODELS = [
  'gemini-2.5-flash-lite',
  'gemini-2.0-flash',
  'gemini-2.0-flash-lite',
];

const GEMINI_API_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

const SYSTEM_PROMPT =
  'Eres un experto en apoyo cognitivo para personas con TDAH. ' +
  'Tu objetivo es dividir tareas complejas en pasos atómicos, pequeños y manejables ' +
  'que no generen abrumamiento. ' +
  'Devuelve el resultado ESTRICTAMENTE en formato JSON: una lista de objetos ' +
  'donde cada objeto tenga "titulo" (nombre del paso) y "tiempo_estimado" (duración sugerida en formato "X min"). ' +
  'Genera entre 3 y 7 pasos máximo. ' +
  'No incluyas texto adicional, bloques Markdown ni caracteres extra. Solo el JSON puro.';

// ─────────────────────────────────────────────────────────────
// TIPOS
// ─────────────────────────────────────────────────────────────

interface DesglosarTareaRequest {
  tarea: string;
  tiempoDisponible: string;
}

interface PasoResponse {
  titulo: string;
  tiempo_estimado: string;
}

// ─────────────────────────────────────────────────────────────
// CLOUD FUNCTION: desglosarTarea
// ─────────────────────────────────────────────────────────────

export const desglosarTarea = httpsFn.onCall(
  {
    secrets: [GEMINI_API_KEY],
    timeoutSeconds: 30,
    memory: '256MiB',
    minInstances: 0,
    maxInstances: 10,
  },
  async (request: httpsFn.CallableRequest<DesglosarTareaRequest>): Promise<PasoResponse[]> => {
    if (!request.auth) {
      throw new httpsFn.HttpsError(
        'unauthenticated',
        'Debes iniciar sesión para usar el Súper Experto.',
      );
    }

    const { tarea, tiempoDisponible } = request.data;

    if (!tarea || typeof tarea !== 'string' || tarea.trim().length < 2) {
      throw new httpsFn.HttpsError(
        'invalid-argument',
        'La tarea debe tener al menos 2 caracteres.',
      );
    }

    if (!tiempoDisponible || typeof tiempoDisponible !== 'string') {
      throw new httpsFn.HttpsError(
        'invalid-argument',
        'Debes indicar el tiempo disponible.',
      );
    }

    const tareaLimpia = tarea.trim();
    const prompt = `${SYSTEM_PROMPT}\n\nTarea: "${tareaLimpia}"\nTiempo disponible: ${tiempoDisponible}`;

    let lastError: Error | null = null;

    for (const modelId of GEMINI_MODELS) {
      try {
        const result = await callGemini(modelId, prompt);
        return result;
      } catch (error) {
        lastError = error as Error;

        if (isModelNotFoundError(error)) {
          continue;
        }

        if (isQuotaError(error)) {
          continue;
        }

        if (isFatalError(error)) {
          throw new httpsFn.HttpsError(
            'internal',
            'Error interno del servicio de IA. Intenta de nuevo más tarde.',
          );
        }
      }
    }

    if (lastError && (isQuotaError(lastError) || isServiceUnavailableError(lastError))) {
      console.warn('Todos los modelos Gemini fallaron, usando plan local', {
        userId: request.auth.uid,
        lastError: lastError.message,
      });
      return generarPlanLocal(tareaLimpia, tiempoDisponible);
    }

    throw new httpsFn.HttpsError(
      'internal',
      'No se pudo generar el plan. Intenta de nuevo en unos minutos.',
    );
  },
);

// ─────────────────────────────────────────────────────────────
// LLM: Llamada a Gemini API
// ─────────────────────────────────────────────────────────────

async function callGemini(modelId: string, prompt: string): Promise<PasoResponse[]> {
  const apiKey = GEMINI_API_KEY.value();
  const url = `${GEMINI_API_BASE}/${modelId}:generateContent`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-goog-api-key': apiKey,
    },
    body: JSON.stringify({
      contents: [
        {
          parts: [{ text: prompt }],
        },
      ],
      generationConfig: {
        temperature: 0.4,
        maxOutputTokens: 512,
        responseMimeType: 'application/json',
      },
    }),
    signal: AbortSignal.timeout(15000),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    const statusCode = response.status;

    if (statusCode === 404) {
      throw new Error(`Modelo no encontrado: ${modelId}`);
    }

    if (statusCode === 429) {
      throw new Error(`Cuota excedida: ${errorBody}`);
    }

    if (statusCode === 503) {
      throw new Error(`Servicio no disponible: ${errorBody}`);
    }

    throw new Error(`Error ${statusCode} de Gemini: ${errorBody}`);
  }

  const data = (await response.json()) as GeminiResponse;
  const rawText = extractTextFromResponse(data);

  if (!rawText || rawText.trim().length === 0) {
    throw new Error('Gemini devolvió una respuesta vacía.');
  }

  return parseStepsFromJson(rawText);
}

// ─────────────────────────────────────────────────────────────
// PARSING
// ─────────────────────────────────────────────────────────────

interface GeminiResponse {
  candidates?: Array<{
    content?: {
      parts?: Array<{ text?: string }>;
    };
  }>;
}

function extractTextFromResponse(data: GeminiResponse): string {
  const candidates = data.candidates;
  if (!candidates || candidates.length === 0) return '';

  const content = candidates[0].content;
  if (!content) return '';

  const parts = content.parts;
  if (!parts || parts.length === 0) return '';

  return parts[0].text ?? '';
}

function parseStepsFromJson(rawText: string): PasoResponse[] {
  const jsonText = rawText
    .replace(/```json\s*/g, '')
    .replace(/```\s*/g, '')
    .trim();

  let decoded: unknown;
  try {
    decoded = JSON.parse(jsonText);
  } catch {
    throw new Error('La IA no devolvió un JSON válido.');
  }

  if (!Array.isArray(decoded)) {
    throw new Error('La respuesta de la IA no tiene el formato esperado.');
  }

  return decoded.map((item: unknown): PasoResponse => {
    if (typeof item !== 'object' || item === null) {
      return { titulo: 'Paso sin nombre', tiempo_estimado: '' };
    }

    const obj = item as Record<string, unknown>;
    return {
      titulo: typeof obj['titulo'] === 'string' ? obj['titulo'].trim() : 'Paso sin nombre',
      tiempo_estimado: typeof obj['tiempo_estimado'] === 'string' ? obj['tiempo_estimado'].trim() : '',
    };
  });
}

// ─────────────────────────────────────────────────────────────
// FALLBACK: Plan local sin IA
// ─────────────────────────────────────────────────────────────

function generarPlanLocal(tarea: string, tiempoDisponible: string): PasoResponse[] {
  const minutos = parseMinutos(tiempoDisponible);
  const bloques = minutos <= 30 ? 4 : minutos <= 60 ? 5 : 6;
  const minutosPorBloque = Math.min(90, Math.max(5, Math.round(minutos / bloques)));
  const tareaLimpia = tarea.replace(/\s+/g, ' ');

  const pasosTexto = [
    `Definir el resultado esperado de "${tareaLimpia}"`,
    'Reunir lo necesario para avanzar',
    'Separar la tarea en partes pequeñas',
    'Hacer la primera parte concreta',
    'Revisar lo hecho y ajustar el siguiente paso',
    'Cerrar con una entrega o avance visible',
  ];

  return pasosTexto.slice(0, bloques).map((titulo) => ({
    titulo,
    tiempo_estimado: `${minutosPorBloque} min`,
  }));
}

function parseMinutos(tiempo: string): number {
  switch (tiempo) {
    case '30 minutos':
      return 30;
    case '1 hora':
      return 60;
    case 'Medio dia':
    case 'Medio día':
      return 240;
    case 'Todo el dia':
    case 'Todo el día':
      return 480;
    case 'Una semana':
      return 1200;
    default:
      return 60;
  }
}

// ─────────────────────────────────────────────────────────────
// UTILS: Clasificación de errores
// ─────────────────────────────────────────────────────────────

function isModelNotFoundError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  return error.message.includes('Modelo no encontrado') || error.message.includes('404');
}

function isQuotaError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  const msg = error.message.toLowerCase();
  return msg.includes('cuota') || msg.includes('quota') || msg.includes('rate limit') || msg.includes('429');
}

function isServiceUnavailableError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  const msg = error.message.toLowerCase();
  return msg.includes('servicio no disponible') || msg.includes('503');
}

function isFatalError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  const msg = error.message.toLowerCase();
  return msg.includes('400') || msg.includes('403') || msg.includes('api key');
}

// ─────────────────────────────────────────────────────────────
// FUNCIONES EXISTENTES (v1) — No modificar
// ─────────────────────────────────────────────────────────────

const firestore = admin.firestore();
const messaging = admin.messaging();

const QUEUE_COLLECTION = 'notificationQueue';
const MAX_PER_RUN = 50;

type QueueDoc = {
  taskId?: string;
  taskTitle?: string;
  runAt?: admin.firestore.Timestamp;
  status?: string;
  type?: string;
  reminderMinutes?: number;
};

export const processDueNotifications = functionsV1.pubsub
  .schedule('every 1 minutes')
  .timeZone('Etc/UTC')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const snapshot = await firestore
      .collectionGroup(QUEUE_COLLECTION)
      .where('status', '==', 'pending')
      .where('runAt', '<=', now)
      .limit(MAX_PER_RUN)
      .get();

    if (snapshot.empty) return null;

    const jobs = snapshot.docs.map(async (doc) => {
      try {
        const data = doc.data() as QueueDoc;
        const userRef = doc.ref.parent.parent;
        if (!userRef) {
          await doc.ref.set(
            {
              status: 'failed',
              lastError: 'Missing user reference',
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
          return;
        }

        const userSnap = await userRef.get();
        if (!userSnap.exists) {
          await doc.ref.set(
            {
              status: 'failed',
              lastError: 'User document not found',
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
          return;
        }

        const userData = userSnap.data() as { fcmTokens?: unknown[] } | undefined;
        const tokens = Array.isArray(userData?.fcmTokens)
          ? (userData!.fcmTokens as unknown[]).filter(
              (token): token is string => typeof token === 'string' && token.trim().length > 0,
            )
          : [];

        if (tokens.length === 0) {
          await doc.ref.set(
            {
              status: 'no_tokens',
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
          return;
        }

        const title = data.taskTitle ?? 'Recordatorio';
        const body = 'Tienes una tarea pendiente.';
        const taskId = data.taskId ?? doc.id;

        const message: admin.messaging.MulticastMessage = {
          tokens,
          notification: { title, body },
          data: {
            taskId,
            type: data.type ?? 'task',
          },
          android: {
            priority: 'high',
            notification: { channelId: 'tareas_channel' },
          },
          apns: {
            payload: {
              aps: {
                contentAvailable: true,
                sound: 'default',
                alert: { title, body },
              },
            },
          },
        };

        const response = await messaging.sendEachForMulticast(message);
        const hasSuccess = response.successCount > 0;

        const invalidCodes = new Set([
          'messaging/registration-token-not-registered',
          'messaging/invalid-registration-token',
          'messaging/mismatched-credential',
          'messaging/invalid-argument',
        ]);
        const invalidTokens = response.responses
          .map((resp, idx) =>
            !resp.success && resp.error && invalidCodes.has(resp.error.code)
              ? tokens[idx]
              : null,
          )
          .filter((token): token is string => !!token);

        if (invalidTokens.length) {
          await userRef.set(
            { fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens) },
            { merge: true },
          );
        }

        await doc.ref.set(
          {
            status: hasSuccess ? 'sent' : 'failed',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            lastError: hasSuccess
              ? admin.firestore.FieldValue.delete()
              : JSON.stringify(response.responses.find((r) => !r.success)?.error ?? {}),
          },
          { merge: true },
        );
      } catch (error) {
        await doc.ref.set(
          {
            status: 'failed',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            lastError: (error as Error).message,
          },
          { merge: true },
        );
      }
    });

    await Promise.all(jobs);
    return null;
  });

// ─────────────────────────────────────────────────────────────
// CLOUD FUNCTION: sintetizarVoz (Google Cloud TTS)
// ─────────────────────────────────────────────────────────────

interface SintetizarVozRequest {
  texto: string;
  vozId?: string;
}

interface SintetizarVozResponse {
  audioContent: string;
  formato: string;
}

const VOCES_DISPONIBLES: Record<string, protos.google.cloud.texttospeech.v1.SsmlVoiceGender> = {
  'neural2-f': protos.google.cloud.texttospeech.v1.SsmlVoiceGender.FEMALE,
  'neural2-b': protos.google.cloud.texttospeech.v1.SsmlVoiceGender.MALE,
  'neural2-a': protos.google.cloud.texttospeech.v1.SsmlVoiceGender.FEMALE,
  'neural2-c': protos.google.cloud.texttospeech.v1.SsmlVoiceGender.MALE,
  'neural2-d': protos.google.cloud.texttospeech.v1.SsmlVoiceGender.MALE,
};

const VOZ_POR_DEFECTO = 'es-US-Neural2-F';
const IDIOMA_POR_DEFECTO = 'es-US';

export const sintetizarVoz = httpsFn.onCall(
  {
    timeoutSeconds: 15,
    memory: '256MiB',
    minInstances: 0,
    maxInstances: 20,
  },
  async (request: httpsFn.CallableRequest<SintetizarVozRequest>): Promise<SintetizarVozResponse> => {
    if (!request.auth) {
      throw new httpsFn.HttpsError(
        'unauthenticated',
        'Debes iniciar sesión para usar la síntesis de voz.',
      );
    }

    const { texto, vozId } = request.data;

    if (!texto || typeof texto !== 'string' || texto.trim().length === 0) {
      throw new httpsFn.HttpsError(
        'invalid-argument',
        'El texto no puede estar vacío.',
      );
    }

    const textoLimpio = texto.trim();

    const client = new TextToSpeechClient();

    const vozSeleccionada = vozId && VOCES_DISPONIBLES[vozId.toLowerCase()]
      ? `es-US-Neural2-${vozId.charAt(vozId.length - 1).toUpperCase()}`
      : VOZ_POR_DEFECTO;

    const gender = VOCES_DISPONIBLES[vozId?.toLowerCase() ?? 'neural2-f'] ??
      protos.google.cloud.texttospeech.v1.SsmlVoiceGender.FEMALE;

    try {
      const [response] = await client.synthesizeSpeech({
        input: { text: textoLimpio },
        voice: {
          languageCode: IDIOMA_POR_DEFECTO,
          name: vozSeleccionada,
          ssmlGender: gender,
        },
        audioConfig: {
          audioEncoding: protos.google.cloud.texttospeech.v1.AudioEncoding.MP3,
          speakingRate: 0.92,
          pitch: 1.0,
          volumeGainDb: 1.0,
          effectsProfileId: ['small-bluetooth-speaker-class-device'],
        },
      });

      if (!response.audioContent) {
        throw new httpsFn.HttpsError(
          'internal',
          'No se pudo generar el audio.',
        );
      }

      return {
        audioContent: Buffer.from(response.audioContent as Uint8Array).toString('base64'),
        formato: 'mp3',
      };
    } catch (error) {
      console.error('Error en sintetizarVoz:', error);

      if ((error as { code?: number }).code === 8) {
        throw new httpsFn.HttpsError(
          'resource-exhausted',
          'Se alcanzó el límite de uso del servicio de voz.',
        );
      }

      throw new httpsFn.HttpsError(
        'internal',
        'Error al sintetizar la voz. Intenta de nuevo.',
      );
    }
  },
);
