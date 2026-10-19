-- Klassifikaatorite nimetuste ühine pikkus, kohustuslikkus ja sisureegel.
CREATE DOMAIN klassifikaatori_nimetus AS varchar(100)
    NOT NULL
    CONSTRAINT ck_klassifikaatori_nimetus_sisu CHECK (VALUE ~ '[^[:space:]]');
COMMENT ON DOMAIN klassifikaatori_nimetus IS
    'Klassifikaatori kohustuslik nimetus pikkusega kuni 100 märki; peab sisaldama vähemalt ühte mittetühimärki.';
