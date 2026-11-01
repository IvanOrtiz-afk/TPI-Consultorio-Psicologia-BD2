USE ConsultorioDB;
GO

CREATE INDEX IX_AntecedentesProfesionales_IdPaciente
    ON dbo.AntecedentesProfesionales(IdPaciente);
GO

CREATE INDEX IX_AntecedentesProfesionales_IdProfesional
    ON dbo.AntecedentesProfesionales(IdProfesional);
GO

USE ConsultorioDB;
GO

SELECT
    COUNT(*) AS CantidadTablas
FROM sys.tables
WHERE is_ms_shipped = 0;
GO

SELECT
    name AS NombreTabla
FROM sys.tables
WHERE is_ms_shipped = 0
ORDER BY name;
GO

USE ConsultorioDB;
GO

SELECT
    OBJECT_NAME(fk.parent_object_id) AS TablaOrigen,
    fk.name AS NombreRelacion,
    OBJECT_NAME(fk.referenced_object_id) AS TablaRelacionada
FROM sys.foreign_keys AS fk
ORDER BY TablaOrigen, NombreRelacion;
GO

USE ConsultorioDB;
GO

SELECT
    OBJECT_NAME(parent_object_id) AS Tabla,
    name AS Restriccion,
    type_desc AS Tipo
FROM sys.objects
WHERE type IN ('C', 'UQ', 'PK')
  AND is_ms_shipped = 0
ORDER BY Tabla, Tipo, Restriccion;
GO

USE ConsultorioDB;
GO

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

-- TRIGGER: validar que el paciente esté activo
-- antes de insertar turnos.

CREATE OR ALTER TRIGGER dbo.TR_Turnos_ValidarPacienteActivo
ON dbo.Turnos
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.Pacientes AS p
            ON p.IdPaciente = i.IdPaciente
        WHERE p.Estado <> 'Activo'
    )
    BEGIN
        ROLLBACK TRANSACTION;

        THROW 50001,
            'No se pueden crear turnos para pacientes que no estén activos.',
            1;
    END;
END;
GO

USE ConsultorioDB;
GO

SELECT
    name AS NombreTrigger,
    OBJECT_NAME(parent_id) AS TablaAsociada,
    is_disabled AS Deshabilitado
FROM sys.triggers
WHERE name = 'TR_Turnos_ValidarPacienteActivo';
GO

-- TRIGGER: impedir superposición de turnos
-- Cada sesión dura 60 minutos.

CREATE OR ALTER TRIGGER dbo.TR_Turnos_EvitarSuperposicion
ON dbo.Turnos
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM dbo.Turnos AS t1
        INNER JOIN dbo.Turnos AS t2
            ON t1.IdTurno < t2.IdTurno
           AND t1.FechaHoraInicio < t2.FechaHoraFin
           AND t1.FechaHoraFin > t2.FechaHoraInicio
    )
    BEGIN
        RAISERROR(
            'La operacion genera una superposicion entre turnos.',
            16,
            1
        );

        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

USE ConsultorioDB;
GO

SELECT
    name AS NombreTrigger,
    OBJECT_NAME(parent_id) AS TablaAsociada,
    is_disabled AS Deshabilitado
FROM sys.triggers
WHERE name = 'TR_Turnos_EvitarSuperposicion';
GO

USE ConsultorioDB;
GO

SELECT
    name AS NombreTrigger,
    OBJECT_NAME(parent_id) AS TablaAsociada,
    is_disabled AS Deshabilitado
FROM sys.triggers
WHERE name = 'TR_Turnos_EvitarSuperposicion';
GO

USE ConsultorioDB;
GO

SELECT
    (SELECT COUNT(*) FROM dbo.Pacientes) AS CantidadPacientes,
    (SELECT COUNT(*) FROM dbo.Turnos) AS CantidadTurnos;
GO

USE ConsultorioDB;
GO

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

--trigger intencional

USE ConsultorioDB;
GO

INSERT INTO dbo.Turnos
    (IdPaciente, FechaHoraInicio, Modalidad, ImporteAplicado)
VALUES
    (1, '2026-10-26T10:30:00', 'Presencial', 15000);
GO