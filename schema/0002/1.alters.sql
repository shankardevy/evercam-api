--
-- known_models
--
ALTER TABLE firmwares ADD COLUMN known_models text[];
UPDATE firmwares SET known_models = '{*}';
ALTER TABLE firmwares ALTER COLUMN known_models SET NOT NULL;

--
-- firmware_id
--
ALTER TABLE devices ALTER COLUMN firmware_id DROP NOT NULL;

