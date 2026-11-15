USE ConsultorioDB;
GO

--primera - turnos y estado de pagos

CREATE OR ALTER VIEW dbo.VW_Turnos_Detalle
AS
SELECT
    t.IdTurno,
    p.IdPaciente,
    p.Nombre,
    p.Apellido,
    p.DNI,
    t.FechaHoraInicio,
    t.FechaHoraFin,
    t.Modalidad,
    t.Estado,
    t.ImporteAplicado,

    ISNULL(pg.ImporteTotal, 0) AS ImportePagado,
    ISNULL(b.Importe, 0) AS ImporteBonificado,

    t.ImporteAplicado
        - ISNULL(pg.ImporteTotal, 0)
        - ISNULL(b.Importe, 0) AS SaldoPendiente

FROM dbo.Turnos AS t
INNER JOIN dbo.Pacientes AS p
    ON p.IdPaciente = t.IdPaciente

LEFT JOIN dbo.PagosTurnos AS pt
    ON pt.IdTurno = t.IdTurno

LEFT JOIN dbo.Pagos AS pg
    ON pg.IdPago = pt.IdPago

LEFT JOIN dbo.Bonificaciones AS b
    ON b.IdTurno = t.IdTurno;
GO

--segunda - resumen de pagos pacientes, saldo pendiente, cobrado, bonificado

CREATE OR ALTER VIEW dbo.VW_Pacientes_ResumenEconomico
AS
SELECT
    p.IdPaciente,
    p.Nombre,
    p.Apellido,
    p.DNI,

    COUNT(v.IdTurno) AS CantidadTurnos,

    ISNULL(SUM(v.ImporteAplicado), 0) AS TotalGenerado,
    ISNULL(SUM(v.ImportePagado), 0) AS TotalPagado,
    ISNULL(SUM(v.ImporteBonificado), 0) AS TotalBonificado,
    ISNULL(SUM(v.SaldoPendiente), 0) AS DeudaPendiente

FROM dbo.Pacientes AS p
LEFT JOIN dbo.VW_Turnos_Detalle AS v
    ON v.IdPaciente = p.IdPaciente

GROUP BY
    p.IdPaciente,
    p.Nombre,
    p.Apellido,
    p.DNI;
GO

--tercera - detalle de pagos registrados

CREATE OR ALTER VIEW dbo.VW_Pagos_Detalle
AS
SELECT
    p.IdPago,
    pa.IdPaciente,
    pa.Nombre,
    pa.Apellido,
    pa.DNI,
    p.FechaPago,
    p.MetodoPago,
    p.ImporteTotal,
    p.Observaciones,
    COUNT(pt.IdTurno) AS CantidadTurnos

FROM dbo.Pagos AS p
INNER JOIN dbo.Pacientes AS pa
    ON pa.IdPaciente = p.IdPaciente

LEFT JOIN dbo.PagosTurnos AS pt
    ON pt.IdPago = p.IdPago

GROUP BY
    p.IdPago,
    pa.IdPaciente,
    pa.Nombre,
    pa.Apellido,
    pa.DNI,
    p.FechaPago,
    p.MetodoPago,
    p.ImporteTotal,
    p.Observaciones;
GO