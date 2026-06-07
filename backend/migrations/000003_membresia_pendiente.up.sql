-- Flujo de pago por constancia (Yape):
--   pendiente   -> el admin asignó un plan, el socio aún no paga
--   en_revision -> el socio envió su N° de operación, falta que el admin confirme
ALTER TYPE estado_membresia ADD VALUE IF NOT EXISTS 'pendiente';
ALTER TYPE estado_membresia ADD VALUE IF NOT EXISTS 'en_revision';

-- N° de operación Yape que declara el socio al pagar (su constancia).
ALTER TABLE membresia ADD COLUMN IF NOT EXISTS operacion_yape TEXT;
