-- =====================================================================
-- Reversión de la migración 000001
-- Se eliminan los objetos en orden inverso al de creación
-- para respetar las dependencias de claves foráneas.
-- =====================================================================

DROP TABLE IF EXISTS asistencia;
DROP TABLE IF EXISTS pago;
DROP TABLE IF EXISTS membresia;
DROP TABLE IF EXISTS plan;
DROP TABLE IF EXISTS socio;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS gimnasio;

DROP TYPE IF EXISTS metodo_pago;
DROP TYPE IF EXISTS estado_membresia;
DROP TYPE IF EXISTS rol_usuario;
