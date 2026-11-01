
USE ConsultorioDB;
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

--trigger intencional

USE ConsultorioDB;
GO

INSERT INTO dbo.Turnos
    (IdPaciente, FechaHoraInicio, Modalidad, ImporteAplicado)
VALUES
    (1, '2026-10-26T10:30:00', 'Presencial', 15000);
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
        FROM inserted AS i --INSERTED es una tabla temporal que SQL Server proporciona dentro de los triggers
        INNER JOIN dbo.Turnos AS t --contiene los registros que acaba de insertar la operacion
            ON t.FechaHoraInicio < i.FechaHoraFin --compara el turno con uno existente de los registros
           AND t.FechaHoraFin > i.FechaHoraInicio --si es menor o mayor da el OK
           AND t.IdTurno <> i.IdTurno
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

--creacion de paciente y ficha inicial

CREATE OR ALTER TRIGGER dbo.TR_Pacientes_CrearFichaYEstadoInicial
ON dbo.Pacientes
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- creo una ficha clínica para cada paciente nuevo.
    INSERT INTO dbo.FichaClinica
        (IdPaciente, FechaCreacion)
    SELECT
        i.IdPaciente,
        SYSDATETIME()
    FROM inserted AS i;

    --registro el estado inicial de cada paciente.
    INSERT INTO dbo.HistorialEstadosPaciente
        (IdPaciente, Estado, FechaCambio, Observaciones)
    SELECT
        i.IdPaciente,
        'Activo',
        SYSDATETIME(),
        'Estado inicial al dar de alta al paciente.'
    FROM inserted AS i;
END;
GO


