
USE ConsultorioDB;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    --------------------------------------------------
    -- 1. PACIENTES
  

    INSERT INTO dbo.Pacientes
    (
        Nombre,
        Apellido,
        DNI,
        FechaAlta,
        Estado
    )
    VALUES
    (
        'Paciente',
        'Prueba',
        '99999999',
        '2026-10-25',
        'Activo'
    );

    DECLARE @IdPaciente INT = SCOPE_IDENTITY();


    --------------------------------------------------
    -- 2. planificaciones (turnos agendados)

    INSERT INTO dbo.PlanificacionesAtencion
    (
        IdPaciente,
        Frecuencia,
        DiaSemana,
        Hora,
        FechaInicio,
        Activa
    )
    VALUES
    (
        @IdPaciente,
        'Semanal',
        1,
        '10:00',
        '2026-10-26',
        1
    );

    DECLARE @IdPlanificacion INT = SCOPE_IDENTITY();


    --------------------------------------------------
    -- 3 honorarios

    INSERT INTO dbo.Honorarios
    (
        IdPaciente,
        Modalidad,
        Importe,
        FechaDesde
    )
    VALUES
    (
        @IdPaciente,
        'Presencial',
        15000.00,
        '2026-10-26'
    );


    --------------------------------------------------
    -- 4. TURNOS
    

    -- turno pagado

    INSERT INTO dbo.Turnos
    (
        IdPaciente,
        IdPlanificacion,
        FechaHoraInicio,
        Modalidad,
        Estado,
        ImporteAplicado
    )
    VALUES
    (
        @IdPaciente,
        @IdPlanificacion,
        '2026-10-26T10:00:00',
        'Presencial',
        'Programado',
        15000.00
    );

    DECLARE @IdTurnoPagado INT = SCOPE_IDENTITY();


    -- turno reprogramado y bonificado

    INSERT INTO dbo.Turnos
    (
        IdPaciente,
        IdPlanificacion,
        FechaHoraInicio,
        Modalidad,
        Estado,
        ImporteAplicado
    )
    VALUES
    (
        @IdPaciente,
        @IdPlanificacion,
        '2026-11-30T10:00:00',
        'Presencial',
        'Programado',
        15000.00
    );

    DECLARE @IdTurnoBonificado INT = SCOPE_IDENTITY();


    -- Turno pendiente de pago

    INSERT INTO dbo.Turnos
    (
        IdPaciente,
        IdPlanificacion,
        FechaHoraInicio,
        Modalidad,
        Estado,
        ImporteAplicado
    )
    VALUES
    (
        @IdPaciente,
        @IdPlanificacion,
        '2026-12-07T10:00:00',
        'Presencial',
        'Programado',
        15000.00
    );

    DECLARE @IdTurnoPendiente INT = SCOPE_IDENTITY();


    --------------------------------------------------
    -- 5. fistorial reprogram.

    INSERT INTO dbo.HistorialReprogramaciones
    (
        IdTurno,
        FechaHoraAnterior,
        FechaHoraNueva,
        Motivo
    )
    VALUES
    (
        @IdTurnoBonificado,
        '2026-11-23T10:00:00',
        '2026-11-30T10:00:00',
        'Reprogramación de turno.'
    );


    --------------------------------------------------
    -- 6. PAGOS
   

    INSERT INTO dbo.Pagos
    (
        IdPaciente,
        ImporteTotal,
        MetodoPago,
        Observaciones
    )
    VALUES
    (
        @IdPaciente,
        15000.00,
        'Transferencia',
        'Pago correspondiente al turno.'
    );

    DECLARE @IdPago INT = SCOPE_IDENTITY();


    --------------------------------------------------
    -- 7. pagos respecto de turnos

    INSERT INTO dbo.PagosTurnos
    (
        IdPago,
        IdTurno
    )
    VALUES
    (
        @IdPago,
        @IdTurnoPagado
    );


    --------------------------------------------------
    -- 8. BONIFICACIONES
   

    INSERT INTO dbo.Bonificaciones
    (
        IdTurno,
        Importe,
        Motivo
    )
    VALUES
    (
        @IdTurnoBonificado,
        5000.00,
        'Bonificación aplicada al turno.'
    );


    --------------------------------------------------
    -- 9. registros clinicos

    INSERT INTO dbo.RegistrosClinicos
    (
        IdPaciente,
        IdTurno,
        Contenido,
        Observaciones
    )
    VALUES
    (
        @IdPaciente,
        @IdTurnoPagado,
        'Registro clínico de ejemplo.',
        'Dato ficticio utilizado para pruebas.'
    );


    --------------------------------------------------
    -- 10. profesionales con los que se atiende/atendio

    INSERT INTO dbo.Profesionales
    (
        Nombre,
        Apellido,
        Especialidad,
        Matricula,
        Institucion,
        Observaciones
    )
    VALUES
    (
        'Laura',
        'Fernandez',
        'Psiquiatria',
        'MN-12345',
        'Centro de Salud Ejemplo',
        'Profesional externo de ejemplo.'
    );

    DECLARE @IdProfesional INT = SCOPE_IDENTITY();


    --------------------------------------------------
    -- 11. antecedentes

    INSERT INTO dbo.AntecedentesProfesionales
    (
        IdPaciente,
        IdProfesional,
        FechaInicio,
        FechaFin,
        Observaciones
    )
    VALUES
    (
        @IdPaciente,
        @IdProfesional,
        '2026-10-01',
        NULL,
        'Seguimiento externo de psiquiatría.'
    );


    --------------------------------------------------
    -- 12. actividades

    INSERT INTO dbo.Actividades
    (
        Nombre,
        Descripcion
    )
    VALUES
    (
        'Dibujar flor',
        'Actividad donde los colores dicen mucho de la persona.'
    ),
    (
        'Ejercicio de crear un cuento',
        'Se muestran imágenes al paciente con la consigna de desarrollar una historia.'
    ),
    (
        'Diario de pensamientos',
        'Anotar las diferentes emociones durante el día.'
    );


    --------------------------------------------------
    -- 13. activiades del paciente

    INSERT INTO dbo.ActividadesPaciente
    (
        IdPaciente,
        IdActividad,
        FechaAsignacion,
        FechaLimite,
        Estado,
        Resultado,
        Observaciones
    )
    SELECT
        @IdPaciente,
        a.IdActividad,
        '2026-11-14',
        datos.FechaLimite,
        datos.Estado,
        datos.Resultado,
        datos.Observaciones
    FROM
    (
        VALUES
        (
            'Dibujar flor',
            CONVERT(DATE, '2026-11-18'),
            'Realizada',
            'Actividad completada.',
            'El paciente realizó la actividad.'
        ),
        (
            'Ejercicio de crear un cuento',
            CONVERT(DATE, '2026-11-20'),
            'En curso',
            NULL,
            'Actividad en desarrollo.'
        ),
        (
            'Diario de pensamientos',
            CONVERT(DATE, '2026-11-23'),
            'Pendiente',
            NULL,
            'Pendiente de realización.'
        )
    ) AS datos
    (
        NombreActividad,
        FechaLimite,
        Estado,
        Resultado,
        Observaciones
    )
    INNER JOIN dbo.Actividades AS a
        ON a.Nombre = datos.NombreActividad;


    --------------------------------------------------
    -- 14. OBJETIVOS
 

    INSERT INTO dbo.Objetivos
    (
        Descripcion
    )
    VALUES
    (
        'Mejorar la relacion con familiar'
    ),
    (
        'Enojarse menos durante una semana'
    ),
    (
        'Fortalecer la autoestima y la confianza personal'
    );


    --------------------------------------------------
    -- 15. historial de objetivos
  

    INSERT INTO dbo.HistorialObjetivosPaciente
    (
        IdPaciente,
        IdObjetivo,
        FechaAsignacion,
        EstadoObjetivo,
        EsActual
    )
    SELECT
        @IdPaciente,
        IdObjetivo,
        '2026-11-14',
        'En curso',
        1
    FROM dbo.Objetivos
    WHERE Descripcion =
        'Fortalecer la autoestima y la confianza personal';


   --------------------------------------------------

    COMMIT TRANSACTION;

    PRINT 'Datos de ejemplo cargados correctamente.';

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;
GO

--crear mas pacientes

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Crear paciente que posteriormente estará de Alta.

    INSERT INTO dbo.Pacientes
    (
        Nombre, Apellido, DNI, FechaAlta, Estado
    )
    VALUES
    (
        'Carlos', 'Rodriguez', '99999994',
        '2026-11-14', 'Activo'
    );

    DECLARE @IdPacienteAlta INT = SCOPE_IDENTITY();

    UPDATE dbo.Pacientes
    SET Estado = 'Alta'
    WHERE IdPaciente = @IdPacienteAlta;

    INSERT INTO dbo.HistorialEstadosPaciente
    (
        IdPaciente, Estado, FechaCambio, Observaciones
    )
    VALUES
    (
        @IdPacienteAlta,
        'Alta',
        SYSDATETIME(),
        'Paciente dado de alta del tratamiento.'
    );


    -- 2. Crear paciente que posteriormente estará en Abandono.

    INSERT INTO dbo.Pacientes
    (
        Nombre, Apellido, DNI, FechaAlta, Estado
    )
    VALUES
    (
        'Mariana', 'Lopez', '99999993',
        '2026-11-14', 'Activo'
    );

    DECLARE @IdPacienteAbandono INT = SCOPE_IDENTITY();

    UPDATE dbo.Pacientes
    SET Estado = 'Abandono'
    WHERE IdPaciente = @IdPacienteAbandono;

    INSERT INTO dbo.HistorialEstadosPaciente
    (
        IdPaciente, Estado, FechaCambio, Observaciones
    )
    VALUES
    (
        @IdPacienteAbandono,
        'Abandono',
        SYSDATETIME(),
        'Paciente que interrumpió el tratamiento.'
    );

    COMMIT TRANSACTION;

    PRINT 'Pacientes incorporados correctamente.';

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;
GO

INSERT INTO dbo.Pacientes
(
    Nombre,
    Apellido,
    DNI,
    FechaAlta,
    Estado
)
VALUES
(
    'Roberto',
    'Gomez',
    '99999992',
    '2026-11-14',
    'Activo'
);

SELECT SCOPE_IDENTITY() AS IdNuevoPaciente;

USE ConsultorioDB;
GO

-- Planificación del paciente 2: deudor.
INSERT INTO dbo.PlanificacionesAtencion
(
    IdPaciente,
    Frecuencia,
    DiaSemana,
    Hora,
    FechaInicio,
    Activa
)
VALUES
(
    2,
    'Semanal',
    1,
    '11:00',
    '2026-11-16',
    1
);

-- Planificación del paciente 8: pagos completos.
INSERT INTO dbo.PlanificacionesAtencion
(
    IdPaciente,
    Frecuencia,
    DiaSemana,
    Hora,
    FechaInicio,
    Activa
)
VALUES
(
    8,
    'Semanal',
    1,
    '12:00',
    '2026-11-16',
    1
);
GO

--agregar turnos

USE ConsultorioDB;
GO

-- Turnos del paciente 2
INSERT INTO dbo.Turnos
(
    IdPaciente,
    IdPlanificacion,
    FechaHoraInicio,
    Modalidad,
    Estado,
    ImporteAplicado
)
VALUES
(2, 3, '2026-11-16T11:00:00', 'Presencial', 'Programado', 15000),
(2, 3, '2026-11-23T11:00:00', 'Presencial', 'Programado', 15000),
(2, 3, '2026-11-30T11:00:00', 'Presencial', 'Programado', 15000);


-- Turnos del paciente 8
INSERT INTO dbo.Turnos
(
    IdPaciente,
    IdPlanificacion,
    FechaHoraInicio,
    Modalidad,
    Estado,
    ImporteAplicado
)
VALUES
(8, 2, '2026-11-16T12:00:00', 'Presencial', 'Programado', 15000),
(8, 2, '2026-11-23T12:00:00', 'Presencial', 'Programado', 15000),
(8, 2, '2026-11-30T12:00:00', 'Presencial', 'Programado', 15000);
GO

SELECT
    IdTurno,
    IdPaciente,
    FechaHoraInicio,
    Estado,
    ImporteAplicado
FROM dbo.Turnos
WHERE IdPaciente IN (2, 8)
ORDER BY FechaHoraInicio, IdPaciente;

--registro de pagos
USE ConsultorioDB;
GO

-- Pago del primer turno.
EXEC dbo.SP_RegistrarPago
    @IdPaciente = 8,
    @IdTurno = 13,
    @MetodoPago = 'Transferencia',
    @Observaciones = 'Pago correspondiente al turno del 16/11/2026';

-- Pago del segundo turno.
EXEC dbo.SP_RegistrarPago
    @IdPaciente = 8,
    @IdTurno = 14,
    @MetodoPago = 'Efectivo',
    @Observaciones = 'Pago correspondiente al turno del 23/11/2026';

-- Pago del tercer turno.
EXEC dbo.SP_RegistrarPago
    @IdPaciente = 8,
    @IdTurno = 15,
    @MetodoPago = 'Tarjeta',
    @Observaciones = 'Pago correspondiente al turno del 30/11/2026';
GO

--creo una planificacion

INSERT INTO dbo.PlanificacionesAtencion
(
    IdPaciente,
    Frecuencia,
    DiaSemana,
    Hora,
    FechaInicio,
    Activa
)
VALUES
(
    5,
    'Semanal',
    1,
    '13:00',
    '2026-11-16',
    1
);

USE ConsultorioDB;
GO

INSERT INTO dbo.Turnos
(
    IdPaciente,
    IdPlanificacion,
    FechaHoraInicio,
    Modalidad,
    Estado,
    ImporteAplicado
)
VALUES
(5, 4, '2026-11-16T13:00:00', 'Presencial', 'Programado', 15000),
(5, 4, '2026-11-23T13:00:00', 'Presencial', 'Programado', 15000);
GO


INSERT INTO dbo.Profesionales
(
    Nombre,
    Apellido,
    Especialidad,
    Matricula,
    Institucion,
    Observaciones
)
VALUES
(
    'Mariana',
    'Torres',
    'Psicologia',
    'MN-67890',
    'Centro Integral de Salud',
    'Profesional externo de ejemplo.'
);
GO

--creo antecedentes

INSERT INTO dbo.AntecedentesProfesionales
(
    IdPaciente,
    IdProfesional,
    FechaInicio,
    FechaFin,
    Observaciones
)
VALUES
(
    2, 2, '2026-10-15', NULL,
    'Seguimiento psicológico externo.'
),
(
    5, 1, '2026-09-01', '2026-10-30',
    'Antecedente de seguimiento psiquiátrico.'
),
(
    8, 2, '2026-11-01', NULL,
    'Inicio de seguimiento psicológico.'
);
GO

SELECT
    p.IdPaciente,
    p.Nombre,
    p.Apellido,
    pr.Nombre AS NombreProfesional,
    pr.Apellido AS ApellidoProfesional,
    pr.Especialidad,
    ap.FechaInicio,
    ap.FechaFin
FROM dbo.AntecedentesProfesionales ap
INNER JOIN dbo.Pacientes p
    ON p.IdPaciente = ap.IdPaciente
INNER JOIN dbo.Profesionales pr
    ON pr.IdProfesional = ap.IdProfesional
ORDER BY p.IdPaciente;

--creo objetivos y actividades

-- Actividades disponibles
SELECT *
FROM dbo.Actividades
ORDER BY IdActividad;

-- Objetivos disponibles
SELECT *
FROM dbo.Objetivos
ORDER BY IdObjetivo;

SELECT
    p.IdPaciente,
    p.Nombre,
    p.Apellido,
    COUNT(DISTINCT ap.IdActividadPaciente) AS CantidadActividades,
    COUNT(DISTINCT ho.IdHistorialObjetivo) AS CantidadObjetivos
FROM dbo.Pacientes p
LEFT JOIN dbo.ActividadesPaciente ap
    ON ap.IdPaciente = p.IdPaciente
LEFT JOIN dbo.HistorialObjetivosPaciente ho
    ON ho.IdPaciente = p.IdPaciente
GROUP BY
    p.IdPaciente,
    p.Nombre,
    p.Apellido
ORDER BY p.IdPaciente;
