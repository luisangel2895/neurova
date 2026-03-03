- Arquitectura:
- MVVM es obligatorio en modulos con interfaz.
- No poner logica de negocio dentro de Views.
- Las Views solo renderizan estado y disparan acciones.
- La coordinacion de estado pertenece a ViewModels.

- Domain:
- Los contratos y protocolos viven en Domain.
- Los casos de uso y reglas de negocio viven en Domain.
- Domain no debe depender de UI ni de detalles de infraestructura.
- Los nombres deben reflejar lenguaje del negocio.

- Data:
- Las implementaciones concretas viven en Data.
- Repositorios, servicios y persistencia se resuelven en Data.
- Data debe cumplir contratos definidos por Domain.
- No filtrar detalles tecnicos hacia la capa de presentacion.

- Naming conventions:
- Tipos en PascalCase.
- Propiedades y funciones en camelCase.
- Nombres claros, especificos y orientados a intencion.
- Evitar abreviaturas ambiguas y nombres genericos.

- Manejo de errores:
- No silenciar errores sin justificacion explicita.
- Propagar errores con contexto util para diagnostico.
- Diferenciar errores de dominio, infraestructura y UI.
- Toda ruta critica debe tener estrategia de falla definida.

- UI y estilo:
- No usar estilos inline si existe una pieza equivalente en DesignSystem.
- Reutilizar componentes visuales y tokens compartidos.
- Mantener consistencia visual y semantica entre features.
- Evitar duplicacion de decisiones de presentacion.
