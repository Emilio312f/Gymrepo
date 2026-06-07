ALTER TABLE membresia DROP COLUMN IF EXISTS operacion_yape;
-- PostgreSQL no permite quitar valores de un ENUM de forma segura, así que
-- 'pendiente' y 'en_revision' permanecen en el tipo estado_membresia.
