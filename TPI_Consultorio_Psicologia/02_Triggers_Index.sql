
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
        WHERE p.Estado IS NULL OR p.Estado <> 'Activo'
    )
    BEGIN
        ROLLBACK TRANSACTION;

        THROW 50001,
            'No se pueden crear turnos para pacientes que no estén activos.',
            1;
    END;
END;
GO

-- TRIGGER: impedir superposición de turnos
-- Cada sesión dura 60 minutos.

CREATE OR ALTER TRIGGER dbo.TR_Turnos_EvitarSuperposicion
ON dbo.Turnos
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- superposiciones entre turnos nuevos o modificados
    -- y los turnos existentes.
    IF EXISTS (
        SELECT 1
        FROM inserted AS i --inserted tabla temporal en SQL server para comparar registros
        INNER JOIN dbo.Turnos AS t
            ON t.IdTurno <> i.IdTurno
           AND t.FechaHoraInicio < i.FechaHoraFin --compara el registro, si menor o mayor da el OK
           AND t.FechaHoraFin > i.FechaHoraInicio
    )
    OR EXISTS (
        -- superposiciones entre los propios registros
        -- incluidos en la operacion.
        SELECT 1
        FROM inserted AS i1
        INNER JOIN inserted AS i2
            ON i1.IdTurno < i2.IdTurno
           AND i1.FechaHoraInicio < i2.FechaHoraFin
           AND i1.FechaHoraFin > i2.FechaHoraInicio
    )
    BEGIN
        ROLLBACK TRANSACTION;

        THROW 50002,
            'La operacion genera una superposicion entre turnos.',
            1;
    END;
END;
GO

-- Creacion de paciente y ficha inicial.
-- Validacion obligatoria del estado inicial.

CREATE OR ALTER TRIGGER dbo.TR_Pacientes_CrearFichaYEstadoInicial
ON dbo.Pacientes
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- valida que todo paciente nuevo ingrese como Activo sin excepcion!!!
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE Estado IS NULL OR Estado <> 'Activo'
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50003,
            'Todo paciente nuevo debe registrarse con estado Activo.',
            1;
    END;

    -- crea una ficha clinica para cada paciente nuevo
    INSERT INTO dbo.FichaClinica
        (IdPaciente, FechaCreacion)
    SELECT
        i.IdPaciente,
        SYSDATETIME()
    FROM inserted AS i;

    -- registra el estado inicial del paciente
    INSERT INTO dbo.HistorialEstadosPaciente
        (IdPaciente, Estado, FechaCambio, Observaciones)
    SELECT
        i.IdPaciente,
        'Activo',
        SYSDATETIME(),
        'Observaciones iniciales al dar de alta al paciente.'
    FROM inserted AS i;
END;
GO

--trigger que impide eliminar pacientes que tengan registros asociados con DELETE

CREATE OR ALTER TRIGGER dbo.TR_Pacientes_EvitarEliminacion
ON dbo.Pacientes
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM DELETED AS d
        INNER JOIN dbo.FichaClinica AS f
            ON f.IdPaciente = d.IdPaciente
    )
    OR EXISTS (
        SELECT 1
        FROM DELETED AS d
        INNER JOIN dbo.HistorialEstadosPaciente AS h
            ON h.IdPaciente = d.IdPaciente
    )
    OR EXISTS (
        SELECT 1
        FROM DELETED AS d
        INNER JOIN dbo.Turnos AS t
            ON t.IdPaciente = d.IdPaciente
    )
    OR EXISTS (
        SELECT 1
        FROM DELETED AS d
        INNER JOIN dbo.Pagos AS p
            ON p.IdPaciente = d.IdPaciente
    )
    OR EXISTS (
        SELECT 1
        FROM DELETED AS d
        INNER JOIN dbo.RegistrosClinicos AS r
            ON r.IdPaciente = d.IdPaciente
    )
    BEGIN
        THROW 50030,
            'No se puede eliminar el paciente porque posee historial clinico, administrativo o economico.',
            1;
    END;

    DELETE p
    FROM dbo.Pacientes AS p
    INNER JOIN DELETED AS d
        ON d.IdPaciente = p.IdPaciente;
END;
GO

--trigger que verifica que no se pueda bonificar un turno que ya esta esta pagado ni superar el importe del turno

CREATE OR ALTER TRIGGER dbo.TR_Bonificaciones_EvitarTurnosPagados
ON dbo.Bonificaciones
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Impedir bonificaciones sobre turnos pagados.
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.PagosTurnos AS pt
            ON pt.IdTurno = i.IdTurno
    )
    BEGIN
        ROLLBACK TRANSACTION;

        THROW 50050,
            'No se puede bonificar un turno que ya fue pagado.',
            1;
    END;

    -- Impedir bonificaciones superiores al importe del turno.
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.Turnos AS t
            ON t.IdTurno = i.IdTurno
        WHERE i.Importe > t.ImporteAplicado
    )
    BEGIN
        ROLLBACK TRANSACTION;

        THROW 50051,
            'La bonificacion no puede superar el importe del turno.',
            1;
    END;
END;
GO

--trigger: no se puede vincular un pago con el turno de otro paciente

CREATE OR ALTER TRIGGER dbo.TR_PagosTurnos_ValidarPaciente
ON dbo.PagosTurnos
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.Pagos AS p
            ON p.IdPago = i.IdPago
        INNER JOIN dbo.Turnos AS t
            ON t.IdTurno = i.IdTurno
        WHERE p.IdPaciente <> t.IdPaciente
    )
    BEGIN
        ROLLBACK TRANSACTION;

        THROW 50060,
            'El pago y el turno deben pertenecer al mismo paciente.',
            1;
    END;
END;
GO

--trigger: evita crear registros clinicos a pacientes de otro turno

CREATE OR ALTER TRIGGER dbo.TR_RegistrosClinicos_ValidarPaciente
ON dbo.RegistrosClinicos
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.Turnos AS t
            ON t.IdTurno = i.IdTurno
        WHERE i.IdPaciente <> t.IdPaciente
    )
    BEGIN
        ROLLBACK TRANSACTION;

        THROW 50061,
            'El registro clinico y el turno deben pertenecer al mismo paciente.',
            1;
    END;
END;
GO

