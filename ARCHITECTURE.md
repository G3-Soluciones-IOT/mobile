# Arquitectura IoT Flutter

Base implementada en `lib/`:

- `app/`: bootstrap y tema global.
- `core/`: constantes transversales.
- `features/iot/domain/`: entidades y contrato de repositorio.
- `features/iot/data/`: datasource mock y repositorio concreto.
- `features/iot/presentation/`: controlador, pantallas y widgets.

Estado actual:

- La app funciona solo con `MockIoTDataSource`.
- `IoTRepositoryImpl` separa el origen de datos de la UI.
- No hay conexión activa con backend.

Siguiente paso cuando quieras integrar:

1. Agregar un cliente HTTP en `data/`.
2. Crear DTOs y mappers `DTO -> Entity`.
3. Reintroducir un `RemoteIoTDataSource`.
4. Cambiar el repositorio de mock a remoto o mixto.
