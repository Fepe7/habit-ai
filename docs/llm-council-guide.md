# LLM Council — Guía de uso

## Qué es

Un framework de toma de decisiones que lanza **5 asesores IA independientes** en paralelo, cada uno con un estilo de pensamiento distinto. Después se hace una **peer review anónima** cruzada y un "chairman" sintetiza todo en un veredicto claro.

## Cómo activarlo

Di cualquiera de estas frases en Claude Code:

| Frase | Efecto |
|-------|--------|
| `council this` | Activa el council |
| `run the council` | Activa el council |
| `pressure-test this` | Activa el council |
| `stress-test this` | Activa el council |
| `war room this` | Activa el council |
| `debate this` | Activa el council |

También se activa combinando una decisión real con frases como "should I X or Y", "which option", "I can't decide", "I'm torn between", "validate this".

## Los 5 asesores

| Asesor | Rol | Pregunta clave |
|--------|-----|----------------|
| **The Contrarian** | Busca fallos fatales | "¿Qué va a fallar?" |
| **The First Principles** | Desmonta supuestos | "¿Estamos resolviendo el problema correcto?" |
| **The Expansionist** | Ve oportunidades ocultas | "¿Qué estamos dejando en la mesa?" |
| **The Outsider** | Perspectiva fresca, sin sesgo | "¿Qué ve alguien que no conoce el contexto?" |
| **The Executor** | Factibilidad real | "¿Cómo se hace esto el lunes por la mañana?" |

Las tensiones naturales entre ellos son lo que hace valioso el proceso:
- Contrarian vs. Expansionist (riesgo vs. oportunidad)
- First Principles vs. Executor (repensar vs. ejecutar)
- Outsider como observador neutral

## Proceso paso a paso

```
1. Frame     → Recoger contexto del workspace y reformular la pregunta
2. Convene   → 5 asesores en paralelo (150-300 palabras cada uno)
3. Review    → Peer review anónima cruzada (A-E, aleatorizado)
4. Synthesis → Chairman sintetiza veredicto final
5. Present   → Resultado en markdown en el chat
```

## Formato del veredicto

El chairman produce:

- **Where the Council Agrees** — señales convergentes de alta confianza
- **Where the Council Clashes** — desacuerdos genuinos con explicación
- **Blind Spots the Council Caught** — insights del peer review
- **The Recommendation** — respuesta directa, sin rodeos
- **The One Thing to Do First** — siguiente paso concreto

## Cuándo usarlo

**Sí:**
- Decisiones estratégicas: "¿Lanzo un workshop de 97€ o un curso de 497€?"
- Trade-offs de arquitectura: "¿Cloud Function o escritura directa?"
- Validar posicionamiento o pivotes
- Revisar copy o landing pages
- Decisiones de contratar vs. automatizar

**No:**
- Preguntas factuales con una sola respuesta correcta
- Tareas de creación de contenido
- Resúmenes o procesamiento de datos
- Preguntas triviales sin trade-offs reales

## Ejemplo práctico

```
> council this: para HabitAI, ¿deberíamos implementar 
> notificaciones push con FCM antes de lanzar a Play Store, 
> o lanzar sin push y añadirlo después según feedback?
```

Esto lanza los 5 asesores, cada uno analiza desde su ángulo, y recibes un veredicto estructurado con recomendación clara.
