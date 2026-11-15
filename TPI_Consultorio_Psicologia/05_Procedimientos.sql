
USE ConsultorioDB;
GO


 -- 1: Registrar un pago


CREATE OR ALTER PROCEDURE dbo.SP_RegistrarPago
    @IdPaciente INT,
    @IdTurno INT,
    @MetodoPago VARCHAR(20),
    @Observaciones NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar que exista el paciente
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Pacientes
            WHERE IdPaciente = @IdPaciente
        )
            THROW 50010, 'El paciente indicado no existe.', 1;

        -- Validar el metodo de pago
        IF @MetodoPago IS NULL OR @MetodoPago NOT IN (
            'Efectivo', 'Transferencia', 'Tarjeta', 'Otro'
        )
            THROW 50012, 'El metodo de pago no es valido.', 1;

        -- Validar que el turno exista y pertenezca al paciente
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Turnos
            WHERE IdTurno = @IdTurno
              AND IdPaciente = @IdPaciente
        )
            THROW 50013, 'El turno no existe o no pertenece al paciente.', 1;

        -- Evitar cobrar turnos pagados o bonificados
        IF EXISTS (
            SELECT 1
            FROM dbo.PagosTurnos
            WHERE IdTurno = @IdTurno
        )
        OR EXISTS (
            SELECT 1
            FROM dbo.Bonificaciones
            WHERE IdTurno = @IdTurno
        )
            THROW 50014, 'El turno ya fue pagado o bonificado.', 1;

        -- Obtener el importe del turno
        DECLARE @ImporteTotal DECIMAL(10,2);

        SELECT @ImporteTotal = ImporteAplicado
        FROM dbo.Turnos
        WHERE IdTurno = @IdTurno;

        IF @ImporteTotal IS NULL OR @ImporteTotal <= 0
            THROW 50015, 'El importe del pago debe ser mayor que cero.', 1;

        -- Registrar el pago
        INSERT INTO dbo.Pagos (
            IdPaciente,
            ImporteTotal,
            MetodoPago,
            Observaciones
        )
        VALUES (
            @IdPaciente,
            @ImporteTotal,
            @MetodoPago,
            @Observaciones
        );

        DECLARE @IdPago INT = SCOPE_IDENTITY();

        -- Vincular el pago con el turno
        INSERT INTO dbo.PagosTurnos (
            IdPago,
            IdTurno
        )
        VALUES (
            @IdPago,
            @IdTurno
        );

        COMMIT TRANSACTION;

        SELECT
            @IdPago AS IdPago,
            @IdPaciente AS IdPaciente,
            @IdTurno AS IdTurno,
            @ImporteTotal AS ImporteTotal,
            @MetodoPago AS MetodoPago,
            'Pago registrado correctamente.' AS Resultado;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO



  -- 2: Reporte de turnos por paciente


CREATE OR ALTER PROCEDURE dbo.SP_ReporteTurnosPaciente
    @IdPaciente INT,
    @FechaDesde DATE,
    @FechaHasta DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que exista el paciente
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Pacientes
        WHERE IdPaciente = @IdPaciente
    )
        THROW 50020, 'El paciente indicado no existe.', 1;

    -- Validar las fechas.
    IF @FechaDesde IS NULL OR @FechaHasta IS NULL
        THROW 50021, 'Debe indicar ambas fechas.', 1;

    IF @FechaDesde > @FechaHasta
        THROW 50022, 'La fecha inicial no puede ser posterior a la fecha final.', 1;

    -- Obtener los turnos del paciente dentro del periodo
    SELECT
        IdTurno,
        IdPaciente,
        Nombre,
        Apellido,
        FechaHoraInicio,
        FechaHoraFin,
        Modalidad,
        Estado,
        ImporteAplicado,
        ImportePagado,
        ImporteBonificado,
        SaldoPendiente
    FROM dbo.VW_Turnos_Detalle
    WHERE IdPaciente = @IdPaciente
      AND FechaHoraInicio >= @FechaDesde
      AND FechaHoraInicio < DATEADD(DAY, 1, @FechaHasta)
    ORDER BY FechaHoraInicio;
END;
GO
