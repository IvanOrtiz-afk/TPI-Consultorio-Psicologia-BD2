USE ConsultorioDB;
GO

SELECT DB_NAME() AS BaseDeDatosActual;
GO

-- TABLA: Pacientes
-- Almacena los datos administrativos de cada paciente.

CREATE TABLE dbo.Pacientes
(
    IdPaciente INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Apellido NVARCHAR(100) NOT NULL,
    DNI VARCHAR(20) NOT NULL UNIQUE,
    FechaNacimiento DATE NULL,
    Telefono VARCHAR(30) NULL,
    Email NVARCHAR(150) NULL,
    Direccion NVARCHAR(200) NULL,
    FechaAlta DATE NOT NULL
        CONSTRAINT DF_Pacientes_FechaAlta
        DEFAULT (CONVERT(DATE, GETDATE())),

    Estado VARCHAR(20) NOT NULL
        CONSTRAINT DF_Pacientes_Estado
        DEFAULT ('Activo'),

    CONSTRAINT CK_Pacientes_Estado
        CHECK (Estado IN ('Activo', 'Suspendido', 'Alta', 'Abandono'))
);
GO

-- TABLA: FichaClinica
-- Cada paciente tendrá una única ficha clínica.

CREATE TABLE dbo.FichaClinica
(
    IdFichaClinica INT IDENTITY(1,1) PRIMARY KEY,

    IdPaciente INT NOT NULL UNIQUE,

    FechaCreacion DATETIME2 NOT NULL
        CONSTRAINT DF_FichaClinica_FechaCreacion
        DEFAULT (SYSDATETIME()),

    ObservacionesGenerales NVARCHAR(1000) NULL,

    CONSTRAINT FK_FichaClinica_Pacientes
        FOREIGN KEY (IdPaciente)
        REFERENCES dbo.Pacientes(IdPaciente)
);
GO

-- TABLA: HistorialEstadosPaciente
-- Registra los cambios de estado de cada paciente.

CREATE TABLE dbo.HistorialEstadosPaciente
(
    IdHistorialEstado INT IDENTITY(1,1) PRIMARY KEY,

    IdPaciente INT NOT NULL,

    Estado VARCHAR(20) NOT NULL,

    FechaCambio DATETIME2 NOT NULL
        CONSTRAINT DF_HistorialEstadosPaciente_FechaCambio
        DEFAULT (SYSDATETIME()),

    Observaciones NVARCHAR(500) NULL,

    CONSTRAINT CK_HistorialEstadosPaciente_Estado
        CHECK (Estado IN ('Activo', 'Suspendido', 'Alta', 'Abandono')),

    CONSTRAINT FK_HistorialEstadosPaciente_Pacientes
        FOREIGN KEY (IdPaciente)
        REFERENCES dbo.Pacientes(IdPaciente)
);
GO

CREATE INDEX IX_HistorialEstadosPaciente_IdPaciente
    ON dbo.HistorialEstadosPaciente(IdPaciente);
GO

-- TABLA: PlanificacionesAtencion
-- Define la frecuencia de atención del paciente.

CREATE TABLE dbo.PlanificacionesAtencion
(
    IdPlanificacion INT IDENTITY(1,1) PRIMARY KEY,

    IdPaciente INT NOT NULL,

    Frecuencia VARCHAR(15) NOT NULL,

    DiaSemana TINYINT NOT NULL,

    Hora TIME(0) NOT NULL,

    FechaInicio DATE NOT NULL,

    Activa BIT NOT NULL
        CONSTRAINT DF_PlanificacionesAtencion_Activa
        DEFAULT (1),

    FechaCreacion DATETIME2 NOT NULL
        CONSTRAINT DF_PlanificacionesAtencion_FechaCreacion
        DEFAULT (SYSDATETIME()),

    CONSTRAINT CK_PlanificacionesAtencion_Frecuencia
        CHECK (Frecuencia IN ('Semanal', 'Quincenal', 'Mensual')),

    CONSTRAINT CK_PlanificacionesAtencion_DiaSemana
        CHECK (DiaSemana BETWEEN 1 AND 7),

    CONSTRAINT FK_PlanificacionesAtencion_Pacientes
        FOREIGN KEY (IdPaciente)
        REFERENCES dbo.Pacientes(IdPaciente)
);
GO

-- Un paciente puede tener varias planificaciones historicas
-- pero solamente una activa a la vez.
CREATE UNIQUE INDEX UX_PlanificacionesAtencion_Activa
    ON dbo.PlanificacionesAtencion(IdPaciente)
    WHERE Activa = 1;
GO

-- TABLA: Turnos
-- Registra las sesiones del consultorio.

CREATE TABLE dbo.Turnos
(
    IdTurno INT IDENTITY(1,1) PRIMARY KEY,

    IdPaciente INT NOT NULL,

    IdPlanificacion INT NULL,

    FechaHoraInicio DATETIME2(0) NOT NULL,

    FechaHoraFin AS DATEADD(MINUTE, 60, FechaHoraInicio) PERSISTED,

    Modalidad VARCHAR(15) NOT NULL,

    Estado VARCHAR(15) NOT NULL
        CONSTRAINT DF_Turnos_Estado
        DEFAULT ('Programado'),

    ImporteAplicado DECIMAL(10,2) NOT NULL,

    Observaciones NVARCHAR(500) NULL,

    FechaCreacion DATETIME2 NOT NULL
        CONSTRAINT DF_Turnos_FechaCreacion
        DEFAULT (SYSDATETIME()),

    CONSTRAINT CK_Turnos_Modalidad
        CHECK (Modalidad IN ('Presencial', 'Virtual')),

    CONSTRAINT CK_Turnos_Estado
        CHECK (Estado IN ('Programado', 'Asistido', 'Ausencia', 'Cancelado')),

    CONSTRAINT CK_Turnos_Importe
        CHECK (ImporteAplicado >= 0),

    CONSTRAINT FK_Turnos_Pacientes
        FOREIGN KEY (IdPaciente)
        REFERENCES dbo.Pacientes(IdPaciente),

    CONSTRAINT FK_Turnos_PlanificacionesAtencion
        FOREIGN KEY (IdPlanificacion)
        REFERENCES dbo.PlanificacionesAtencion(IdPlanificacion)
);
GO

CREATE INDEX IX_Turnos_IdPaciente_FechaHoraInicio
    ON dbo.Turnos(IdPaciente, FechaHoraInicio);
GO

CREATE INDEX IX_Turnos_FechaHoraInicio
    ON dbo.Turnos(FechaHoraInicio);
GO

-- TABLA: HistorialReprogramaciones
-- Registra los cambios de fecha y hora de turnos.

CREATE TABLE dbo.HistorialReprogramaciones
(
    IdReprogramacion INT IDENTITY(1,1) PRIMARY KEY,

    IdTurno INT NOT NULL,

    FechaHoraAnterior DATETIME2(0) NOT NULL,

    FechaHoraNueva DATETIME2(0) NOT NULL,

    FechaCambio DATETIME2(0) NOT NULL
        CONSTRAINT DF_HistorialReprogramaciones_FechaCambio
        DEFAULT (SYSDATETIME()),

    Motivo NVARCHAR(500) NULL,

    CONSTRAINT CK_HistorialReprogramaciones_Fechas
        CHECK (FechaHoraAnterior <> FechaHoraNueva),

    CONSTRAINT FK_HistorialReprogramaciones_Turnos
        FOREIGN KEY (IdTurno)
        REFERENCES dbo.Turnos(IdTurno)
);
GO

CREATE INDEX IX_HistorialReprogramaciones_IdTurno
    ON dbo.HistorialReprogramaciones(IdTurno);
GO

-- TABLA: Honorarios
-- Registra los importes por paciente y modalidad.

CREATE TABLE dbo.Honorarios
(
    IdHonorario INT IDENTITY(1,1) PRIMARY KEY,

    IdPaciente INT NOT NULL,

    Modalidad VARCHAR(15) NOT NULL,

    Importe DECIMAL(10,2) NOT NULL,

    FechaDesde DATE NOT NULL,

    FechaHasta DATE NULL,

    FechaCreacion DATETIME2 NOT NULL
        CONSTRAINT DF_Honorarios_FechaCreacion
        DEFAULT (SYSDATETIME()),

    CONSTRAINT CK_Honorarios_Modalidad
        CHECK (Modalidad IN ('Presencial', 'Virtual')),

    CONSTRAINT CK_Honorarios_Importe
        CHECK (Importe > 0),

    CONSTRAINT CK_Honorarios_Vigencia
        CHECK (FechaHasta IS NULL OR FechaHasta >= FechaDesde),

    CONSTRAINT FK_Honorarios_Pacientes
        FOREIGN KEY (IdPaciente)
        REFERENCES dbo.Pacientes(IdPaciente)
);
GO

CREATE INDEX IX_Honorarios_Paciente_Modalidad_Vigencia
    ON dbo.Honorarios(IdPaciente, Modalidad, FechaDesde);
GO

-- TABLA: Pagos
-- Registra los pagos realizados por los pacientes.

CREATE TABLE dbo.Pagos
(
    IdPago INT IDENTITY(1,1) PRIMARY KEY,

    IdPaciente INT NOT NULL,

    FechaPago DATETIME2(0) NOT NULL
        CONSTRAINT DF_Pagos_FechaPago
        DEFAULT (SYSDATETIME()),

    ImporteTotal DECIMAL(10,2) NOT NULL,

    MetodoPago VARCHAR(20) NOT NULL,

    Observaciones NVARCHAR(500) NULL,

    CONSTRAINT CK_Pagos_ImporteTotal
        CHECK (ImporteTotal > 0),

    CONSTRAINT CK_Pagos_MetodoPago
        CHECK (MetodoPago IN
            ('Efectivo', 'Transferencia', 'Tarjeta', 'Otro')),

    CONSTRAINT FK_Pagos_Pacientes
        FOREIGN KEY (IdPaciente)
        REFERENCES dbo.Pacientes(IdPaciente)
);
GO

CREATE INDEX IX_Pagos_IdPaciente_FechaPago
    ON dbo.Pagos(IdPaciente, FechaPago);
GO

-- TABLA: PagosTurnos
-- Relaciona cada pago con los turnos abonados.

CREATE TABLE dbo.PagosTurnos
(
    IdPago INT NOT NULL,

    IdTurno INT NOT NULL,

    CONSTRAINT PK_PagosTurnos
        PRIMARY KEY (IdPago, IdTurno),

    CONSTRAINT UQ_PagosTurnos_IdTurno
        UNIQUE (IdTurno),

    CONSTRAINT FK_PagosTurnos_Pagos
        FOREIGN KEY (IdPago)
        REFERENCES dbo.Pagos(IdPago),

    CONSTRAINT FK_PagosTurnos_Turnos
        FOREIGN KEY (IdTurno)
        REFERENCES dbo.Turnos(IdTurno)
);
GO

-- TABLA: Bonificaciones
-- Registra bonificaciones aplicadas a turnos.

CREATE TABLE dbo.Bonificaciones
(
    IdBonificacion INT IDENTITY(1,1) PRIMARY KEY,

    IdTurno INT NOT NULL,

    Importe DECIMAL(10,2) NOT NULL,

    FechaBonificacion DATETIME2(0) NOT NULL
        CONSTRAINT DF_Bonificaciones_Fecha
        DEFAULT (SYSDATETIME()),

    Motivo NVARCHAR(500) NOT NULL,

    CONSTRAINT UQ_Bonificaciones_IdTurno
        UNIQUE (IdTurno),

    CONSTRAINT CK_Bonificaciones_Importe
        CHECK (Importe > 0),

    CONSTRAINT FK_Bonificaciones_Turnos
        FOREIGN KEY (IdTurno)
        REFERENCES dbo.Turnos(IdTurno)
);
GO

-- TABLA: RegistrosClinicos
-- Guarda registros clínicos asociados al paciente.
-- Un registro puede vincularse opcionalmente a un turno.

CREATE TABLE dbo.RegistrosClinicos
(
    IdRegistroClinico INT IDENTITY(1,1) PRIMARY KEY,

    IdPaciente INT NOT NULL,

    IdTurno INT NULL,

    FechaRegistro DATETIME2(0) NOT NULL
        CONSTRAINT DF_RegistrosClinicos_FechaRegistro
        DEFAULT (SYSDATETIME()),

    Contenido NVARCHAR(MAX) NOT NULL,

    Observaciones NVARCHAR(1000) NULL,

    CONSTRAINT FK_RegistrosClinicos_Pacientes
        FOREIGN KEY (IdPaciente)
        REFERENCES dbo.Pacientes(IdPaciente),

    CONSTRAINT FK_RegistrosClinicos_Turnos
        FOREIGN KEY (IdTurno)
        REFERENCES dbo.Turnos(IdTurno)
);
GO

CREATE INDEX IX_RegistrosClinicos_IdPaciente_FechaRegistro
    ON dbo.RegistrosClinicos(IdPaciente, FechaRegistro);
GO

-- TABLA: Actividades
-- Catálogo de actividades disponibles.

CREATE TABLE dbo.Actividades
(
    IdActividad INT IDENTITY(1,1) PRIMARY KEY,

    Nombre NVARCHAR(150) NOT NULL,

    Descripcion NVARCHAR(1000) NULL,

    Activa BIT NOT NULL
        CONSTRAINT DF_Actividades_Activa
        DEFAULT (1),

    FechaCreacion DATETIME2(0) NOT NULL
        CONSTRAINT DF_Actividades_FechaCreacion
        DEFAULT (SYSDATETIME()),

    CONSTRAINT UQ_Actividades_Nombre
        UNIQUE (Nombre)
);
GO

-- TABLA: ActividadesPaciente
-- Registra las actividades asignadas a pacientes.

CREATE TABLE dbo.ActividadesPaciente
(
    IdActividadPaciente INT IDENTITY(1,1) PRIMARY KEY,

    IdPaciente INT NOT NULL,

    IdActividad INT NOT NULL,

    IdTurno INT NULL,

    FechaAsignacion DATE NOT NULL
        CONSTRAINT DF_ActividadesPaciente_FechaAsignacion
        DEFAULT (CONVERT(DATE, GETDATE())),

    FechaLimite DATE NULL,

    Estado VARCHAR(20) NOT NULL
        CONSTRAINT DF_ActividadesPaciente_Estado
        DEFAULT ('Pendiente'),

    Resultado NVARCHAR(1000) NULL,

    Observaciones NVARCHAR(500) NULL,

    CONSTRAINT CK_ActividadesPaciente_Estado
        CHECK (Estado IN
            ('Pendiente', 'En curso', 'Realizada', 'No realizada')),

    CONSTRAINT CK_ActividadesPaciente_Fechas
        CHECK (FechaLimite IS NULL OR FechaLimite >= FechaAsignacion),

    CONSTRAINT FK_ActividadesPaciente_Pacientes
        FOREIGN KEY (IdPaciente)
        REFERENCES dbo.Pacientes(IdPaciente),

    CONSTRAINT FK_ActividadesPaciente_Actividades
        FOREIGN KEY (IdActividad)
        REFERENCES dbo.Actividades(IdActividad),

    CONSTRAINT FK_ActividadesPaciente_Turnos
        FOREIGN KEY (IdTurno)
        REFERENCES dbo.Turnos(IdTurno)
);
GO

CREATE INDEX IX_ActividadesPaciente_IdPaciente
    ON dbo.ActividadesPaciente(IdPaciente);
GO

-- TABLA: Objetivos
-- Catálogo de objetivos terapéuticos.

CREATE TABLE dbo.Objetivos
(
    IdObjetivo INT IDENTITY(1,1) PRIMARY KEY,

    Descripcion NVARCHAR(500) NOT NULL,

    Activo BIT NOT NULL
        CONSTRAINT DF_Objetivos_Activo
        DEFAULT (1),

    FechaCreacion DATETIME2(0) NOT NULL
        CONSTRAINT DF_Objetivos_FechaCreacion
        DEFAULT (SYSDATETIME()),

    CONSTRAINT UQ_Objetivos_Descripcion
        UNIQUE (Descripcion)
);
GO

-- TABLA: HistorialObjetivosPaciente
-- Registra asignaciones y evolución de objetivos.

CREATE TABLE dbo.HistorialObjetivosPaciente
(
    IdHistorialObjetivo INT IDENTITY(1,1) PRIMARY KEY,

    IdPaciente INT NOT NULL,

    IdObjetivo INT NOT NULL,

    FechaAsignacion DATE NOT NULL
        CONSTRAINT DF_HistorialObjetivosPaciente_FechaAsignacion
        DEFAULT (CONVERT(DATE, GETDATE())),

    FechaCumplimiento DATE NULL,

    EstadoObjetivo VARCHAR(20) NOT NULL
        CONSTRAINT DF_HistorialObjetivosPaciente_Estado
        DEFAULT ('Pendiente'),

    EsActual BIT NOT NULL
        CONSTRAINT DF_HistorialObjetivosPaciente_EsActual
        DEFAULT (1),

    Observaciones NVARCHAR(1000) NULL,

    CONSTRAINT CK_HistorialObjetivosPaciente_Estado
        CHECK (EstadoObjetivo IN
            ('Pendiente', 'En curso', 'Cumplido', 'No cumplido')),

    CONSTRAINT CK_HistorialObjetivosPaciente_Fechas
        CHECK (
            FechaCumplimiento IS NULL
            OR FechaCumplimiento >= FechaAsignacion
        ),

    CONSTRAINT CK_HistorialObjetivosPaciente_Cumplimiento
        CHECK (
            EstadoObjetivo <> 'Cumplido'
            OR FechaCumplimiento IS NOT NULL
        ),

    CONSTRAINT FK_HistorialObjetivosPaciente_Pacientes
        FOREIGN KEY (IdPaciente)
        REFERENCES dbo.Pacientes(IdPaciente),

    CONSTRAINT FK_HistorialObjetivosPaciente_Objetivos
        FOREIGN KEY (IdObjetivo)
        REFERENCES dbo.Objetivos(IdObjetivo)
);
GO

-- Cada paciente puede tener un solo objetivo actual.
CREATE UNIQUE INDEX UX_HistorialObjetivosPaciente_Actual
    ON dbo.HistorialObjetivosPaciente(IdPaciente)
    WHERE EsActual = 1;
GO

-- TABLA: Profesionales
-- Catálogo de profesionales externos.

CREATE TABLE dbo.Profesionales
(
    IdProfesional INT IDENTITY(1,1) PRIMARY KEY,

    Nombre NVARCHAR(100) NOT NULL,

    Apellido NVARCHAR(100) NOT NULL,

    Especialidad NVARCHAR(150) NULL,

    Matricula VARCHAR(50) NULL,

    Institucion NVARCHAR(200) NULL,

    Observaciones NVARCHAR(500) NULL,

    FechaCreacion DATETIME2(0) NOT NULL
        CONSTRAINT DF_Profesionales_FechaCreacion
        DEFAULT (SYSDATETIME())
);
GO

-- TABLA: AntecedentesProfesionales
-- Relaciona pacientes con profesionales externos.

CREATE TABLE dbo.AntecedentesProfesionales
(
    IdAntecedenteProfesional INT IDENTITY(1,1) PRIMARY KEY,

    IdPaciente INT NOT NULL,

    IdProfesional INT NOT NULL,

    FechaInicio DATE NULL,

    FechaFin DATE NULL,

    Observaciones NVARCHAR(1000) NULL,

    FechaRegistro DATETIME2(0) NOT NULL
        CONSTRAINT DF_AntecedentesProfesionales_FechaRegistro
        DEFAULT (SYSDATETIME()),

    CONSTRAINT CK_AntecedentesProfesionales_Fechas
        CHECK (
            FechaInicio IS NULL
            OR FechaFin IS NULL
            OR FechaFin >= FechaInicio
        ),

    CONSTRAINT FK_AntecedentesProfesionales_Pacientes
        FOREIGN KEY (IdPaciente)
        REFERENCES dbo.Pacientes(IdPaciente),

    CONSTRAINT FK_AntecedentesProfesionales_Profesionales
        FOREIGN KEY (IdProfesional)
        REFERENCES dbo.Profesionales(IdProfesional)
);
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

USE ConsultorioDB;
GO

CREATE OR ALTER TRIGGER dbo.TR_Turnos_EvitarSuperposicion
ON dbo.Turnos
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.Turnos AS t
            ON t.FechaHoraInicio < i.FechaHoraFin
           AND t.FechaHoraFin > i.FechaHoraInicio
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