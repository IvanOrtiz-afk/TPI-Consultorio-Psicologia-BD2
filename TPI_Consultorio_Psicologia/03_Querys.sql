USE ConsultorioDB;
GO

INSERT INTO dbo.Turnos
    (IdPaciente, FechaHoraInicio, Modalidad, ImporteAplicado)
VALUES
    (1, '2026-10-26T10:30:00', 'Presencial', 15000);
GO

USE ConsultorioDB;
GO

SELECT
    IdTurno,
    FechaHoraInicio,
    FechaHoraFin,
    Estado,
    ImporteAplicado
FROM dbo.Turnos;
GO

USE ConsultorioDB;
GO

EXEC sp_help 'dbo.FichaClinica';
GO

USE ConsultorioDB;
GO

SELECT
    COLUMN_NAME AS Columna,
    DATA_TYPE AS TipoDato,
    IS_NULLABLE AS PermiteNulos,
    CHARACTER_MAXIMUM_LENGTH AS Longitud
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'FichaClinica'
ORDER BY ORDINAL_POSITION;
GO

USE ConsultorioDB;
GO

SELECT
    COLUMN_NAME AS Columna,
    DATA_TYPE AS TipoDato,
    IS_NULLABLE AS PermiteNulos,
    CHARACTER_MAXIMUM_LENGTH AS Longitud
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'HistorialEstadosPaciente'
ORDER BY ORDINAL_POSITION;
GO

--trigger intencional

USE ConsultorioDB;
GO

INSERT INTO dbo.Turnos
    (IdPaciente, FechaHoraInicio, Modalidad, ImporteAplicado)
VALUES
    (1, '2026-10-26T10:30:00', 'Presencial', 15000);
GO

USE ConsultorioDB;
GO

SELECT
    IdTurno,
    IdPaciente,
    FechaHoraInicio,
    FechaHoraFin,
    Estado,
    ImporteAplicado
FROM dbo.Turnos
ORDER BY FechaHoraInicio;
GO

--verifico cant de tablas

SELECT
    COUNT(*) AS CantidadTablas
FROM sys.tables
WHERE is_ms_shipped = 0;
GO

--listo tablas creadas

SELECT
    name AS NombreTabla
FROM sys.tables
WHERE is_ms_shipped = 0
ORDER BY name;
GO

--verifico las FK

SELECT
    OBJECT_NAME(fk.parent_object_id) AS TablaOrigen,
    fk.name AS NombreRelacion,
    OBJECT_NAME(fk.referenced_object_id) AS TablaRelacionada
FROM sys.foreign_keys AS fk
ORDER BY TablaOrigen, NombreRelacion;
GO

--listar las restricciones de las tablas

SELECT
    OBJECT_NAME(parent_object_id) AS Tabla,
    name AS Restriccion,
    type_desc AS Tipo
FROM sys.objects
WHERE type IN ('C', 'UQ', 'PK')
  AND is_ms_shipped = 0
ORDER BY Tabla, Tipo, Restriccion;
GO

--verifico indices si existen y mostrar que tienen

SELECT
    t.name AS Tabla,
    i.name AS Indice,
    i.is_unique AS EsUnico,
    i.has_filter AS TieneFiltro,
    i.filter_definition AS Filtro
FROM sys.indexes AS i
INNER JOIN sys.tables AS t
    ON i.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND i.index_id > 0
  AND (
      t.name IN ('Pacientes', 'FichaClinica',
                 'PlanificacionesAtencion', 'Turnos',
                 'Honorarios', 'PagosTurnos',
                 'Bonificaciones',
                 'HistorialObjetivosPaciente')
  )
ORDER BY t.name, i.name;
GO

--verificar si los triggers existen

SELECT
    name AS NombreTrigger,
    OBJECT_NAME(parent_id) AS TablaAsociada,
    is_disabled AS Deshabilitado
FROM sys.triggers
WHERE name = 'TR_Turnos_EvitarSuperposicion';
GO

SELECT
    name AS NombreTrigger,
    OBJECT_NAME(parent_id) AS TablaAsociada,
    is_disabled AS Deshabilitado
FROM sys.triggers
WHERE name = 'TR_Turnos_EvitarSuperposicion';
GO

--conteo de registros

SELECT
    (SELECT COUNT(*) FROM dbo.Pacientes) AS CantidadPacientes,
    (SELECT COUNT(*) FROM dbo.Turnos) AS CantidadTurnos;
GO

--pruebas!!!

INSERT INTO dbo.Pacientes
    (Nombre, Apellido, DNI, Estado)
VALUES
    ('Paciente', 'Prueba', '99999999', 'Activo');
GO

SELECT *
FROM dbo.Pacientes
WHERE DNI = '99999999';
GO

USE ConsultorioDB;
GO

INSERT INTO dbo.Turnos
    (IdPaciente, FechaHoraInicio, Modalidad, ImporteAplicado)
VALUES
    (1, '2026-10-26T10:00:00', 'Presencial', 15000);
GO

SELECT
    IdTurno,
    IdPaciente,
    FechaHoraInicio,
    FechaHoraFin,
    Estado,
    ImporteAplicado
FROM dbo.Turnos
WHERE IdPaciente = 1;
GO

INSERT INTO dbo.Pacientes (Nombre, Apellido, DNI, Estado)
VALUES ('Paciente', 'PruebaTrigger', '99999998', 'Activo');
GO
