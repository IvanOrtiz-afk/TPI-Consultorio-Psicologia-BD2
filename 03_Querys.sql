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


USE ConsultorioDB;
GO

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

USE ConsultorioDB;
GO

INSERT INTO dbo.Pacientes (Nombre, Apellido, DNI, Estado)
VALUES ('Paciente', 'PruebaTrigger', '99999998', 'Activo');
GO

