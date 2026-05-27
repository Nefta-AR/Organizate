import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime, timedelta
import matplotlib
matplotlib.rcParams['font.family'] = 'sans-serif'
matplotlib.rcParams['font.sans-serif'] = ['Arial', 'Helvetica', 'DejaVu Sans']
matplotlib.rcParams['axes.unicode_minus'] = False

# Project phases data
phases = [
    {"name": "Fase 1: Fundación y Auth", "start": "2026-04-27", "end": "2026-04-28", "status": "done", "pct": 100},
    {"name": "Fase 2: IA / Súper Experto", "start": "2026-04-28", "end": "2026-04-29", "status": "done", "pct": 100},
    {"name": "Fase 3: Módulo TEA (Pictogramas)", "start": "2026-04-30", "end": "2026-05-06", "status": "done", "pct": 100},
    {"name": "Fase 4: Módulo TDAH (Tareas y Foco)", "start": "2026-05-05", "end": "2026-05-09", "status": "done", "pct": 100},
    {"name": "Fase 5: Integración y Correcciones", "start": "2026-05-09", "end": "2026-05-23", "status": "done", "pct": 100},
    {"name": "Fase 6: Pulido y Testing", "start": "2026-05-24", "end": "2026-06-16", "status": "progress", "pct": 75},
    {"name": "Fase 7: Documentación y Entrega", "start": "2026-06-17", "end": "2026-07-07", "status": "pending", "pct": 0},
]

# Key milestones
milestones = [
    {"name": "HITO 1: Vinculación Tutor-Usuario", "date": "2026-05-13", "status": "done"},
    {"name": "HITO 2: Sincronización Completa", "date": "2026-05-26", "status": "done"},
    {"name": "HITO 3: MVP Listo", "date": "2026-06-30", "status": "pending"},
    {"name": "HITO 4: Entrega Final", "date": "2026-07-07", "status": "pending"},
]

# Create figure
fig, ax = plt.subplots(figsize=(16, 8))
fig.patch.set_facecolor('#f8f9fa')
ax.set_facecolor('#f8f9fa')

# Colors
colors = {
    "done": "#4CAF50",
    "progress": "#2196F3",
    "pending": "#9E9E9E",
}

# Plot phases
y_positions = range(len(phases))
for i, phase in enumerate(phases):
    start = datetime.strptime(phase["start"], "%Y-%m-%d")
    end = datetime.strptime(phase["end"], "%Y-%m-%d")
    duration = (end - start).days + 1
    
    # Full bar
    ax.barh(i, duration, left=start, height=0.6, color=colors[phase["status"]], alpha=0.8, edgecolor='white', linewidth=1)
    
    # Progress overlay for in-progress phase
    if phase["status"] == "progress" and phase["pct"] > 0:
        progress_duration = duration * phase["pct"] / 100
        ax.barh(i, progress_duration, left=start, height=0.6, color=colors["done"], alpha=0.9, edgecolor='white', linewidth=1)
    
    # Label
    label = f"{phase['name']} ({phase['pct']}%)"
    ax.text(start + timedelta(days=duration/2), i, label, 
            ha='center', va='center', fontsize=10, fontweight='bold', color='white')

# Plot milestones
for m in milestones:
    date = datetime.strptime(m["date"], "%Y-%m-%d")
    marker = '★' if m["status"] == "done" else '☆'
    color = colors["done"] if m["status"] == "done" else colors["pending"]
    ax.axvline(x=date, color=color, linestyle='--', alpha=0.5, linewidth=1)
    ax.text(date, len(phases) - 0.5, f"{marker} {m['name']}", 
            ha='center', va='bottom', fontsize=9, color=color, fontweight='bold', rotation=45)

# Formatting
ax.set_yticks(list(y_positions))
ax.set_yticklabels([f"F{i+1}" for i in y_positions], fontsize=10)
ax.set_xlim(datetime(2026, 4, 25), datetime(2026, 7, 10))
ax.xaxis.set_major_formatter(mdates.DateFormatter('%d %b'))
ax.xaxis.set_major_locator(mdates.WeekdayLocator(interval=1))
ax.grid(axis='x', alpha=0.3, linestyle='--')
ax.set_xlabel('Fecha', fontsize=11, fontweight='bold')
ax.set_title('Carta Gantt — Proyecto Simple\n27 Abril - 07 Julio 2026', 
             fontsize=14, fontweight='bold', pad=20)

# Legend
from matplotlib.patches import Patch
legend_elements = [
    Patch(facecolor=colors["done"], label='Completado'),
    Patch(facecolor=colors["progress"], label='En Progreso'),
    Patch(facecolor=colors["pending"], label='Pendiente'),
]
ax.legend(handles=legend_elements, loc='upper right', fontsize=9)

plt.tight_layout()
plt.savefig('gantt_simple.png', dpi=150, bbox_inches='tight', facecolor='#f8f9fa')
plt.close()
print("Gantt chart generated: gantt_simple.png")
