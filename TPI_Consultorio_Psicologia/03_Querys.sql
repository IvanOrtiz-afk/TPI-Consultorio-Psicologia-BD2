
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

--PARA EL VIDEO

USE ConsultorioDB;
GO

SELECT * FROM Pacientes ORDER BY IdPaciente;

SELECT * FROM FichaClinica ORDER BY IdPaciente;

SELECT * FROM HistorialEstadosPaciente
ORDER BY IdPaciente, FechaCambio;

-------------------------

SELECT * FROM PlanificacionesAtencion;

SELECT * FROM Honorarios;

SELECT * FROM Turnos
ORDER BY FechaHoraInicio;

SELECT * FROM HistorialReprogramaciones;

--------------------------

SELECT * FROM Pagos;

SELECT * FROM PagosTurnos;

SELECT * FROM Bonificaciones;

--------------------------

SELECT * FROM RegistrosClinicos;

SELECT * FROM Actividades;

SELECT * FROM ActividadesPaciente;

SELECT * FROM Objetivos;

SELECT * FROM HistorialObjetivosPaciente;

SELECT * FROM Profesionales;

SELECT * FROM AntecedentesProfesionales;

---------------------------

SELECT
    IdPaciente,
    Nombre,
    Apellido,
    Estado
FROM Pacientes
ORDER BY IdPaciente;

----------------------------

SELECT
    IdTurno,
    IdPaciente,
    FechaHoraInicio,
    FechaHoraFin,
    Estado
FROM Turnos
ORDER BY IdPaciente, FechaHoraInicio;

-----------------------------

SELECT
    p.IdPaciente,
    p.Nombre,
    p.Apellido,
    p.Estado,
    f.IdFichaClinica,
    f.FechaCreacion
FROM Pacientes AS p
INNER JOIN FichaClinica AS f
    ON f.IdPaciente = p.IdPaciente;

------------------------------

SELECT *
FROM HistorialEstadosPaciente
ORDER BY IdPaciente, FechaCambio;

------------------------------

SELECT
    IdTurno,
    ImporteAplicado,
    ImportePagado,
    ImporteBonificado,
    SaldoPendiente
FROM VW_Turnos_Detalle
WHERE IdTurno = 8;

-------------------------------

SELECT
    pt.IdPago,
    p.IdPaciente AS PacienteDelPago,
    pt.IdTurno,
    t.IdPaciente AS PacienteDelTurno
FROM PagosTurnos AS pt
INNER JOIN Pagos AS p
    ON p.IdPago = pt.IdPago
INNER JOIN Turnos AS t
    ON t.IdTurno = pt.IdTurno;

--------------------------------

SELECT
    r.IdRegistroClinico,
    r.IdPaciente AS PacienteDelRegistro,
    r.IdTurno,
    t.IdPaciente AS PacienteDelTurno
FROM RegistrosClinicos AS r
LEFT JOIN Turnos AS t
    ON t.IdTurno = r.IdTurno;

--------------------------------

SELECT *
FROM VW_Turnos_Detalle
ORDER BY IdTurno;

--------------------------------

SELECT *
FROM VW_Pacientes_ResumenEconomico
ORDER BY IdPaciente;

--------------------------------

SELECT *
FROM VW_Pagos_Detalle
ORDER BY IdPago;

--------------------------------

SELECT *
FROM Pagos;

SELECT *
FROM PagosTurnos;

--------------------------------

EXEC dbo.SP_ReporteTurnosPaciente
    @IdPaciente = 1,
    @FechaDesde = '2026-10-01',
    @FechaHasta = '2026-12-31';

-------------------------------- TESTING!!!


/*
============================================================
PRUEBAS VIDEO

IMPORTANTE:
Ejecutar cada consulta por separado
Las consultas que generan errores deben probarse individualmente
No ejecutar todo el archivo de una sola vez para el que lo quiera testear
============================================================
*/

USE ConsultorioDB;
GO

---------------------------------------

SELECT DB_NAME() AS BaseDeDatosActual;
GO

-- Cant de tablas
SELECT COUNT(*) AS CantidadTablas
FROM sys.tables
WHERE is_ms_shipped = 0;
GO

-- Listado de tablas
SELECT name AS NombreTabla
FROM sys.tables
WHERE is_ms_shipped = 0
ORDER BY name;
GO

-- Cant de registros por tabla
SELECT
    t.name AS Tabla,
    SUM(p.rows) AS CantidadRegistros
FROM sys.tables AS t
INNER JOIN sys.partitions AS p
    ON p.object_id = t.object_id
WHERE p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY t.name;
GO

-- Relaciones entre tablas
SELECT
    OBJECT_NAME(fk.parent_object_id) AS TablaOrigen,
    fk.name AS NombreRelacion,
    OBJECT_NAME(fk.referenced_object_id) AS TablaRelacionada
FROM sys.foreign_keys AS fk
ORDER BY TablaOrigen, NombreRelacion;
GO

-------------------------------------------------

SELECT * FROM dbo.Pacientes;
GO

SELECT * FROM dbo.FichaClinica;
GO

SELECT * FROM dbo.HistorialEstadosPaciente;
GO

SELECT * FROM dbo.PlanificacionesAtencion;
GO

SELECT * FROM dbo.Turnos;
GO

SELECT * FROM dbo.HistorialReprogramaciones;
GO

SELECT * FROM dbo.Honorarios;
GO

SELECT * FROM dbo.Pagos;
GO

SELECT * FROM dbo.PagosTurnos;
GO

SELECT * FROM dbo.Bonificaciones;
GO

SELECT * FROM dbo.RegistrosClinicos;
GO

SELECT * FROM dbo.Actividades;
GO

SELECT * FROM dbo.ActividadesPaciente;
GO

SELECT * FROM dbo.Objetivos;
GO

SELECT * FROM dbo.HistorialObjetivosPaciente;
GO

SELECT * FROM dbo.Profesionales;
GO

SELECT * FROM dbo.AntecedentesProfesionales;
GO


-----------------------------------------------------

SELECT
    name AS NombreTrigger,
    OBJECT_NAME(parent_id) AS TablaAsociada,
    type_desc AS TipoTrigger,
    is_disabled AS Deshabilitado
FROM sys.triggers
WHERE is_ms_shipped = 0
ORDER BY TablaAsociada, NombreTrigger;
GO


--------------------------------------------------

INSERT INTO dbo.Pacientes
    (Nombre, Apellido, DNI, Estado)
VALUES
    ('Eduardo', 'Perez', '35236326', 'Activo');
GO

INSERT INTO dbo.Pacientes
    (Nombre, Apellido, DNI, Estado)
VALUES
    ('Iker', 'Rodriguez', '35124326', 'Activo');
GO

------------------------------------------------

INSERT INTO dbo.Pacientes
    (Nombre, Apellido, DNI, Estado)
VALUES
    ('PacienteTESTF', 'Ortiz', '992349002', 'Suspendido');
GO

----------------------------------------------------

SELECT
    IdPaciente,
    Nombre,
    Apellido,
    Estado
FROM dbo.Pacientes
GO

INSERT INTO dbo.Turnos
    (IdPaciente, FechaHoraInicio, Modalidad, ImporteAplicado)
VALUES
    (36, '2027-05-28T10:00:00', 'Presencial', 15000);
GO

INSERT INTO dbo.Turnos
    (IdPaciente, FechaHoraInicio, Modalidad, ImporteAplicado)
VALUES
    (1, '2027-05-28T10:00:00', 'Presencial', 15000);
GO

----------------------------------------------------

SELECT
    IdTurno,
    IdPaciente,
    FechaHoraInicio,
    FechaHoraFin,
    Estado,
    ImporteAplicado
FROM dbo.Turnos
WHERE IdTurno = 1;
GO

-----------------------------------------------

INSERT INTO dbo.Turnos
    (IdPaciente, FechaHoraInicio, Modalidad, ImporteAplicado)
VALUES
    (15, '2029-03-02T10:30:00', 'Presencial', 15000);
GO


----------------------------------------------

DELETE FROM dbo.Pacientes
WHERE IdPaciente = 36;
GO

-- Comprobar que el paciente continua existiendo

SELECT
    IdPaciente,
    Nombre,
    Apellido,
    Estado
FROM dbo.Pacientes
WHERE IdPaciente = 36;
GO


------------------------------------------------

SELECT
    t.IdTurno,
    t.ImporteAplicado,
    pt.IdPago,
    b.Importe AS ImporteBonificado
FROM dbo.Turnos AS t
LEFT JOIN dbo.PagosTurnos AS pt
    ON pt.IdTurno = t.IdTurno
LEFT JOIN dbo.Bonificaciones AS b
    ON b.IdTurno = t.IdTurno
WHERE t.IdTurno = 1;
GO

INSERT INTO dbo.Bonificaciones
    (IdTurno, Importe, Motivo)
VALUES
    (56, 5000, 'bonif sobre un turno pagado?');
GO


----------------------------------------------

SELECT
    IdTurno,
    IdPaciente,
    Nombre,
    FechaHoraInicio

    FROM VW_Turnos_Detalle;

INSERT INTO dbo.RegistrosClinicos
(
    IdPaciente,
    IdTurno,
    Contenido,
    Observaciones
)
VALUES
(
    1,
    1,
    'asociacion a turno de otro paciente',
    'no deberia entrar'
);
GO


-------------------------------------------------
--si un registro clinico se asocia a un tirno ambos deben pertenecer al mismo paciente
SELECT
    rc.IdRegistroClinico,
    rc.IdPaciente AS PacienteRegistro,
    rc.IdTurno,
    t.IdPaciente AS PacienteTurno
FROM dbo.RegistrosClinicos AS rc
LEFT JOIN dbo.Turnos AS t
    ON t.IdTurno = rc.IdTurno;
GO

SELECT
    IdTurno,
    IdPaciente,
    Nombre

    FROM VW_Turnos_Detalle;

-------------------------------------------------

UPDATE dbo.RegistrosClinicos --no deberia entrar ya que intenta modificar para el paciende ID 1 un turno que pertenece a otro paciente
    SET IdTurno = 36 WHERE IdPaciente = 1;

    INSERT INTO dbo.Turnos
    (IdPaciente, FechaHoraInicio, Modalidad, ImporteAplicado)
VALUES
    (1, '2029-04-02T10:30:00', 'Virtual', 15000);
GO


    UPDATE dbo.RegistrosClinicos --si deberia entrar
    SET IdTurno = 42 WHERE IdPaciente = 1;


-------------------------------------------------

SELECT *
FROM dbo.VW_Turnos_Detalle
ORDER BY IdTurno;
GO

-- Mostrar ejemplos especificos

SELECT *
FROM dbo.VW_Turnos_Detalle
WHERE IdTurno IN (1, 8, 9);
GO

-----------------------------------------------

SELECT *
FROM dbo.VW_Pacientes_ResumenEconomico
ORDER BY IdPaciente;
GO

-- Mostrar un paciente especifico

SELECT *
FROM dbo.VW_Pacientes_ResumenEconomico
WHERE IdPaciente = 1;
GO


-------------------------------------------

SELECT *
FROM dbo.VW_Pagos_Detalle
ORDER BY IdPago;
GO


------------------------------------------

EXEC dbo.SP_ReporteTurnosPaciente
    @IdPaciente = 1,
    @FechaDesde = '2026-10-01',
    @FechaHasta = '2026-12-31';
GO

-------------------------------------------

EXEC dbo.SP_ReporteTurnosPaciente
    @IdPaciente = 9999,
    @FechaDesde = '2026-10-01',
    @FechaHasta = '2026-12-31';
GO

--------------------------------------------

EXEC dbo.SP_ReporteTurnosPaciente
    @IdPaciente = 1,
    @FechaDesde = '2026-12-31',
    @FechaHasta = '2026-10-01';
GO

--------------------------------------------

--muestro los turnos hechos
SELECT
IdTurno,
IdPaciente,
FechaHoraInicio,
FechaHoraFin
    FROM dbo.VW_Turnos_Detalle;

--registro un pago nuevo para el turno que quiera
EXEC dbo.SP_RegistrarPago
    @IdPaciente = 12,
    @IdTurno = 45,
    @MetodoPago = 'Transferencia',
    @Observaciones = 'Pago de prueba para el TPI.';
GO

--verifico
SELECT
    IdPago,
    IdPaciente,
    ImporteTotal,
    MetodoPago,
    FechaPago
FROM dbo.Pagos 

--------------------------------------------

EXEC sp_helptext 'dbo.SP_RegistrarPago';
GO


EXEC sp_help 'dbo.ListaTurnosPago';
GO

----------------------------------------

SELECT
    name AS NombreFuncion,
    type_desc AS TipoFuncion
FROM sys.objects
WHERE type IN ('FN', 'IF', 'TF')
  AND is_ms_shipped = 0
ORDER BY name;
GO


-- Vistas, procedimientos y triggers

SELECT
    o.type_desc AS TipoObjeto,
    o.name AS NombreObjeto
FROM sys.objects AS o
WHERE o.is_ms_shipped = 0
  AND o.type IN ('V', 'P', 'TR')
ORDER BY o.type_desc, o.name;
GO

-- Estado final de los turnos

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

-- Estado final de los pacientes

SELECT
    IdPaciente,
    Nombre,
    Apellido,
    DNI,
    Estado
FROM dbo.Pacientes
ORDER BY IdPaciente;
GO

-- Resumen economico

SELECT *
FROM dbo.VW_Pacientes_ResumenEconomico
ORDER BY IdPaciente;
GO

