-- ============================================================
-- PROYECTO FINAL - BASE DE DATOS (100000SI33)
-- Sistema de Gestión: Empresa de Transporte "TransVías S.A.C."
-- Motor: PostgreSQL
-- ============================================================

-- ============================================================
-- SECCIÓN 1: CREACIÓN DE BASE DE DATOS Y ESQUEMA
-- ============================================================

-- Ejecutar primero como superusuario:
-- CREATE DATABASE bd_transvias;
-- \c bd_transvias

CREATE SCHEMA IF NOT EXISTS tv;

-- ============================================================
-- SECCIÓN 2: CREACIÓN DE TABLAS (DDL)
-- ============================================================

CREATE TABLE tv.conductor (
    id_conductor   SERIAL        PRIMARY KEY,
    dni            CHAR(8)       NOT NULL UNIQUE,
    nombres        VARCHAR(80)   NOT NULL,
    apellidos      VARCHAR(80)   NOT NULL,
    fecha_nac      DATE          NOT NULL,
    tipo_licencia  VARCHAR(5)    NOT NULL CHECK (tipo_licencia IN ('A1','A2','A2B','A3','A3B')),
    fecha_venc_lic DATE          NOT NULL,
    telefono       VARCHAR(15),
    estado         BOOLEAN       NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE  tv.conductor IS 'Conductores habilitados de la empresa TransVías S.A.C.';
COMMENT ON COLUMN tv.conductor.tipo_licencia IS 'Categoría MTC Perú';

CREATE TABLE tv.vehiculo (
    id_vehiculo    SERIAL        PRIMARY KEY,
    placa          VARCHAR(8)    NOT NULL UNIQUE,
    tipo           VARCHAR(20)   NOT NULL CHECK (tipo IN ('BUS','MINIVAN','FURGONETA')),
    marca          VARCHAR(40)   NOT NULL,
    modelo         VARCHAR(40)   NOT NULL,
    anio           SMALLINT      NOT NULL CHECK (anio BETWEEN 1990 AND 2030),
    capacidad      SMALLINT      NOT NULL CHECK (capacidad > 0),
    estado         VARCHAR(15)   NOT NULL DEFAULT 'operativo'
                                 CHECK (estado IN ('operativo','mantenimiento','baja')),
    fecha_registro TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE tv.vehiculo IS 'Flota de vehículos de la empresa.';

CREATE TABLE tv.ruta (
    id_ruta         SERIAL        PRIMARY KEY,
    ciudad_origen   VARCHAR(60)   NOT NULL,
    ciudad_destino  VARCHAR(60)   NOT NULL,
    distancia_km    NUMERIC(7,2)  NOT NULL CHECK (distancia_km > 0),
    duracion_horas  NUMERIC(5,2)  NOT NULL CHECK (duracion_horas > 0),
    estado          BOOLEAN       NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_ruta UNIQUE (ciudad_origen, ciudad_destino)
);
COMMENT ON TABLE tv.ruta IS 'Rutas definidas entre ciudades.';

CREATE TABLE tv.tarifa (
    id_tarifa      SERIAL        PRIMARY KEY,
    id_ruta        INTEGER       NOT NULL REFERENCES tv.ruta(id_ruta),
    tipo_servicio  VARCHAR(10)   NOT NULL CHECK (tipo_servicio IN ('NORMAL','VIP','CAMA')),
    precio         NUMERIC(8,2)  NOT NULL CHECK (precio > 0),
    CONSTRAINT uq_tarifa UNIQUE (id_ruta, tipo_servicio)
);
COMMENT ON TABLE tv.tarifa IS 'Tarifas por ruta y tipo de servicio.';

CREATE TABLE tv.empleado (
    id_empleado    SERIAL        PRIMARY KEY,
    dni            CHAR(8)       NOT NULL UNIQUE,
    nombres        VARCHAR(80)   NOT NULL,
    apellidos      VARCHAR(80)   NOT NULL,
    cargo          VARCHAR(40)   NOT NULL CHECK (cargo IN ('VENDEDOR','DESPACHADOR','SUPERVISOR','ADMINISTRADOR')),
    telefono       VARCHAR(15),
    correo         VARCHAR(100),
    estado         BOOLEAN       NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE tv.empleado IS 'Personal administrativo y operativo.';

CREATE TABLE tv.viaje (
    id_viaje          SERIAL        PRIMARY KEY,
    id_ruta           INTEGER       NOT NULL REFERENCES tv.ruta(id_ruta),
    id_vehiculo       INTEGER       NOT NULL REFERENCES tv.vehiculo(id_vehiculo),
    id_conductor      INTEGER       NOT NULL REFERENCES tv.conductor(id_conductor),
    id_empleado       INTEGER       NOT NULL REFERENCES tv.empleado(id_empleado),
    fecha_salida      TIMESTAMP     NOT NULL,
    fecha_llegada_est TIMESTAMP     NOT NULL,
    estado            VARCHAR(15)   NOT NULL DEFAULT 'programado'
                                    CHECK (estado IN ('programado','en_curso','completado','cancelado')),
    tipo_servicio     VARCHAR(10)   NOT NULL CHECK (tipo_servicio IN ('NORMAL','VIP','CAMA')),
    CONSTRAINT ck_fechas CHECK (fecha_llegada_est > fecha_salida)
);
COMMENT ON TABLE tv.viaje IS 'Viajes programados con ruta, vehículo y conductor.';

CREATE TABLE tv.pasajero (
    id_pasajero    SERIAL        PRIMARY KEY,
    dni            CHAR(8)       NOT NULL UNIQUE,
    nombres        VARCHAR(80)   NOT NULL,
    apellidos      VARCHAR(80)   NOT NULL,
    telefono       VARCHAR(15),
    correo         VARCHAR(100),
    estado         BOOLEAN       NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE tv.pasajero IS 'Pasajeros registrados que adquieren boletos.';

CREATE TABLE tv.boleto (
    id_boleto      SERIAL        PRIMARY KEY,
    id_viaje       INTEGER       NOT NULL REFERENCES tv.viaje(id_viaje),
    id_pasajero    INTEGER       NOT NULL REFERENCES tv.pasajero(id_pasajero),
    id_empleado    INTEGER       NOT NULL REFERENCES tv.empleado(id_empleado),
    nro_asiento    SMALLINT      NOT NULL CHECK (nro_asiento > 0),
    precio         NUMERIC(8,2)  NOT NULL CHECK (precio > 0),
    fecha_venta    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado         VARCHAR(15)   NOT NULL DEFAULT 'activo'
                                 CHECK (estado IN ('activo','cancelado','usado')),
    CONSTRAINT uq_asiento_viaje UNIQUE (id_viaje, nro_asiento)
);
COMMENT ON TABLE tv.boleto IS 'Boletos vendidos por pasajero y viaje (entidad débil).';

CREATE TABLE tv.encomienda (
    id_encomienda        SERIAL        PRIMARY KEY,
    id_viaje             INTEGER       NOT NULL REFERENCES tv.viaje(id_viaje),
    dni_remitente        CHAR(8)       NOT NULL,
    nombre_remitente     VARCHAR(100)  NOT NULL,
    dni_destinatario     CHAR(8)       NOT NULL,
    nombre_destinatario  VARCHAR(100)  NOT NULL,
    descripcion          VARCHAR(200)  NOT NULL,
    peso_kg              NUMERIC(6,2)  NOT NULL CHECK (peso_kg > 0),
    precio               NUMERIC(8,2)  NOT NULL CHECK (precio > 0),
    estado_actual        VARCHAR(15)   NOT NULL DEFAULT 'REGISTRADO'
                                       CHECK (estado_actual IN ('REGISTRADO','EN_TRANSITO','ENTREGADO','DEVUELTO')),
    fecha_registro       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_remit_dest CHECK (dni_remitente <> dni_destinatario)
);
COMMENT ON TABLE tv.encomienda IS 'Paquetes transportados en los viajes.';

CREATE TABLE tv.estado_encomienda (
    id_estado      SERIAL        PRIMARY KEY,
    id_encomienda  INTEGER       NOT NULL REFERENCES tv.encomienda(id_encomienda),
    estado         VARCHAR(15)   NOT NULL CHECK (estado IN ('REGISTRADO','EN_TRANSITO','ENTREGADO','DEVUELTO')),
    fecha_cambio   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacion    VARCHAR(200)
);
COMMENT ON TABLE tv.estado_encomienda IS 'Historial de cambios de estado de encomiendas.';

CREATE TABLE tv.pago (
    id_pago        SERIAL        PRIMARY KEY,
    id_boleto      INTEGER       REFERENCES tv.boleto(id_boleto),
    id_encomienda  INTEGER       REFERENCES tv.encomienda(id_encomienda),
    monto          NUMERIC(8,2)  NOT NULL CHECK (monto > 0),
    metodo_pago    VARCHAR(15)   NOT NULL CHECK (metodo_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA','YAPE','PLIN')),
    fecha_pago     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado         VARCHAR(10)   NOT NULL DEFAULT 'PAGADO' CHECK (estado IN ('PAGADO','ANULADO')),
    CONSTRAINT ck_pago_exclusivo CHECK (
        (id_boleto IS NOT NULL AND id_encomienda IS NULL) OR
        (id_boleto IS NULL     AND id_encomienda IS NOT NULL)
    )
);
COMMENT ON TABLE tv.pago IS 'Pagos de boletos o encomiendas (exclusivos).';

CREATE TABLE tv.mantenimiento (
    id_mantenimiento SERIAL        PRIMARY KEY,
    id_vehiculo      INTEGER       NOT NULL REFERENCES tv.vehiculo(id_vehiculo),
    tipo             VARCHAR(15)   NOT NULL CHECK (tipo IN ('PREVENTIVO','CORRECTIVO')),
    descripcion      VARCHAR(200)  NOT NULL,
    fecha_inicio     DATE          NOT NULL,
    fecha_fin        DATE,
    costo            NUMERIC(10,2) CHECK (costo >= 0),
    estado           VARCHAR(15)   NOT NULL DEFAULT 'pendiente'
                                   CHECK (estado IN ('pendiente','en_proceso','completado')),
    CONSTRAINT ck_fechas_mant CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);
COMMENT ON TABLE tv.mantenimiento IS 'Mantenimientos preventivos y correctivos de la flota.';

-- ============================================================
-- SECCIÓN 3: ÍNDICES JUSTIFICADOS (6)
-- ============================================================

-- Búsqueda frecuente de conductor por DNI en ventanilla
CREATE INDEX idx_conductor_dni       ON tv.conductor(dni);
-- Filtro de viajes por fecha de salida (reportes diarios/semanales)
CREATE INDEX idx_viaje_fecha_salida  ON tv.viaje(fecha_salida);
-- Verificación de asientos disponibles por viaje
CREATE INDEX idx_boleto_viaje        ON tv.boleto(id_viaje);
-- Búsqueda de pasajero por DNI en ventanilla
CREATE INDEX idx_pasajero_dni        ON tv.pasajero(dni);
-- Seguimiento de encomiendas por estado en tiempo real
CREATE INDEX idx_encomienda_estado   ON tv.encomienda(estado_actual);
-- Consultas de historial de mantenimiento por vehículo
CREATE INDEX idx_mant_vehiculo       ON tv.mantenimiento(id_vehiculo);

-- ============================================================
-- SECCIÓN 4: INSERCIÓN DE DATOS DE PRUEBA
-- ============================================================

-- CONDUCTORES (12)
INSERT INTO tv.conductor (dni,nombres,apellidos,fecha_nac,tipo_licencia,fecha_venc_lic,telefono) VALUES
('72341001','Carlos Enrique','Quispe Mendoza','1985-03-14','A3B','2027-03-14','987654001'),
('72341002','Luis Alberto','Huanca Torres','1979-07-22','A3B','2026-07-22','987654002'),
('72341003','Marco Antonio','Ccopa Rios','1988-11-05','A3','2028-11-05','987654003'),
('72341004','Juan Pablo','Flores Salas','1990-01-30','A2B','2027-01-30','987654004'),
('72341005','Roberto Carlos','Mamani Apaza','1982-06-18','A3B','2029-06-18','987654005'),
('72341006','Felix Augusto','Condori Puma','1975-09-25','A3B','2026-09-25','987654006'),
('72341007','Edgar Samuel','Lazo Vargas','1992-04-12','A2','2028-04-12','987654007'),
('72341008','Wilmer Jose','Pacaya Cruz','1987-12-08','A3','2027-12-08','987654008'),
('72341009','Henry David','Suca Choque','1983-05-20','A3B','2030-05-20','987654009'),
('72341010','Raul Ernesto','Turpo Quispe','1980-08-15','A3B','2028-08-15','987654010'),
('72341011','Nelson Ivan','Cusi Mamani','1991-02-28','A2B','2027-02-28','987654011'),
('72341012','Percy Ronald','Hancco Lima','1977-10-03','A3B','2026-10-03','987654012');

-- VEHÍCULOS (12)
INSERT INTO tv.vehiculo (placa,tipo,marca,modelo,anio,capacidad,estado) VALUES
('ABC-123','BUS','Mercedes-Benz','OF-1721',2018,45,'operativo'),
('ABC-456','BUS','Scania','K410',2020,50,'operativo'),
('ABC-789','BUS','Volvo','B380R',2019,48,'operativo'),
('DEF-123','BUS','Mercedes-Benz','OF-1721',2017,45,'operativo'),
('DEF-456','BUS','Scania','K360',2021,50,'operativo'),
('DEF-789','MINIVAN','Toyota','Hiace',2022,15,'operativo'),
('GHI-123','MINIVAN','Toyota','Hiace',2021,15,'operativo'),
('GHI-456','BUS','Volvo','B420R',2023,52,'operativo'),
('GHI-789','FURGONETA','Mercedes-Benz','Sprinter',2020,8,'operativo'),
('JKL-123','BUS','Scania','K410',2022,50,'mantenimiento'),
('JKL-456','MINIVAN','Toyota','Hiace',2019,15,'operativo'),
('JKL-789','FURGONETA','Ford','Transit',2021,8,'operativo');

-- RUTAS (10)
INSERT INTO tv.ruta (ciudad_origen,ciudad_destino,distancia_km,duracion_horas) VALUES
('Lima','Arequipa',1009.00,14.50),
('Lima','Cusco',1107.00,20.00),
('Lima','Trujillo',557.00,8.00),
('Lima','Piura',973.00,14.00),
('Lima','Huancayo',297.00,6.00),
('Lima','Puno',1291.00,18.00),
('Lima','Ica',303.00,4.50),
('Arequipa','Cusco',521.00,9.00),
('Lima','Chiclayo',770.00,11.00),
('Lima','Ayacucho',564.00,9.00);

-- TARIFAS (25)
INSERT INTO tv.tarifa (id_ruta,tipo_servicio,precio) VALUES
(1,'NORMAL',75.00),(1,'VIP',120.00),(1,'CAMA',160.00),
(2,'NORMAL',100.00),(2,'VIP',150.00),(2,'CAMA',200.00),
(3,'NORMAL',45.00),(3,'VIP',75.00),(3,'CAMA',100.00),
(4,'NORMAL',85.00),(4,'VIP',130.00),(4,'CAMA',170.00),
(5,'NORMAL',30.00),(5,'VIP',50.00),(5,'CAMA',70.00),
(6,'NORMAL',110.00),(6,'VIP',160.00),(6,'CAMA',210.00),
(7,'NORMAL',25.00),(7,'VIP',40.00),
(8,'NORMAL',60.00),(8,'VIP',95.00),(8,'CAMA',130.00),
(9,'NORMAL',55.00),(9,'VIP',90.00);

-- EMPLEADOS (10)
INSERT INTO tv.empleado (dni,nombres,apellidos,cargo,telefono,correo) VALUES
('80001001','Maria Elena','Paredes Rojas','ADMINISTRADOR','999000101','m.paredes@transvias.pe'),
('80001002','Jorge Luis','Cardenas Vega','SUPERVISOR','999000102','j.cardenas@transvias.pe'),
('80001003','Ana Cecilia','Tineo Soto','VENDEDOR','999000103','a.tineo@transvias.pe'),
('80001004','Pedro Miguel','Asto Capcha','VENDEDOR','999000104','p.asto@transvias.pe'),
('80001005','Sandra Luz','Ore Aliaga','VENDEDOR','999000105','s.ore@transvias.pe'),
('80001006','Raul Andres','Huanca Pari','DESPACHADOR','999000106','r.huanca@transvias.pe'),
('80001007','Carmen Rosa','Bautista Inga','DESPACHADOR','999000107','c.bautista@transvias.pe'),
('80001008','Miguel Angel','Sulca Torres','VENDEDOR','999000108','m.sulca@transvias.pe'),
('80001009','Lucia Fernanda','Choque Llana','SUPERVISOR','999000109','l.choque@transvias.pe'),
('80001010','David Isaias','Quispe Nina','VENDEDOR','999000110','d.quispe@transvias.pe');

-- VIAJES (20)
INSERT INTO tv.viaje (id_ruta,id_vehiculo,id_conductor,id_empleado,fecha_salida,fecha_llegada_est,estado,tipo_servicio) VALUES
(1,1,1,3,'2026-06-01 20:00','2026-06-02 10:30','completado','NORMAL'),
(2,2,2,3,'2026-06-02 18:00','2026-06-03 14:00','completado','CAMA'),
(3,3,3,4,'2026-06-03 08:00','2026-06-03 16:00','completado','NORMAL'),
(4,4,4,4,'2026-06-04 20:00','2026-06-05 10:00','completado','VIP'),
(5,6,5,5,'2026-06-05 06:00','2026-06-05 12:00','completado','NORMAL'),
(1,5,6,5,'2026-06-06 21:00','2026-06-07 11:30','completado','VIP'),
(7,7,7,8,'2026-06-07 07:00','2026-06-07 11:30','completado','NORMAL'),
(3,8,8,8,'2026-06-08 09:00','2026-06-08 17:00','completado','VIP'),
(9,1,9,3,'2026-06-09 22:00','2026-06-10 09:00','completado','NORMAL'),
(6,2,10,4,'2026-06-10 17:00','2026-06-11 11:00','completado','CAMA'),
(2,3,1,5,'2026-06-11 19:00','2026-06-12 15:00','completado','VIP'),
(5,11,2,8,'2026-06-12 07:00','2026-06-12 13:00','completado','NORMAL'),
(1,4,3,3,'2026-06-13 20:30','2026-06-14 11:00','completado','CAMA'),
(10,6,4,4,'2026-06-14 08:00','2026-06-14 17:00','completado','NORMAL'),
(3,8,5,5,'2026-06-15 10:00','2026-06-15 18:00','completado','VIP'),
(4,5,6,8,'2026-06-16 21:00','2026-06-17 11:00','en_curso','CAMA'),
(7,7,7,3,'2026-06-17 06:30','2026-06-17 11:00','programado','NORMAL'),
(9,11,8,4,'2026-06-18 23:00','2026-06-19 10:00','programado','VIP'),
(2,8,9,5,'2026-06-19 18:30','2026-06-20 14:30','programado','NORMAL'),
(1,5,10,8,'2026-06-20 20:00','2026-06-21 10:30','programado','VIP');

-- PASAJEROS (15)
INSERT INTO tv.pasajero (dni,nombres,apellidos,telefono,correo) VALUES
('45001001','Carla Sofia','Mendoza Ruiz','911001001','carla.mendoza@gmail.com'),
('45001002','Andres Felipe','Salazar Toro','911001002','andres.salazar@gmail.com'),
('45001003','Paola Renata','Vega Chavez','911001003','paola.vega@gmail.com'),
('45001004','Gonzalo Martin','Ramos Pinto','911001004','gonzalo.ramos@gmail.com'),
('45001005','Valeria Cristina','Nunez Diaz','911001005','valeria.nunez@gmail.com'),
('45001006','Jose Antonio','Benites Lara','911001006','jose.benites@gmail.com'),
('45001007','Natalia Paz','Condor Flores','911001007','natalia.condor@gmail.com'),
('45001008','Ricardo Alonso','Poma Huanca','911001008','ricardo.poma@gmail.com'),
('45001009','Diana Lucia','Cervantes Ore','911001009','diana.cervantes@gmail.com'),
('45001010','Fernando Javier','Aquino Rios','911001010','fernando.aquino@gmail.com'),
('45001011','Milagros Esther','Taipe Luque','911001011','milagros.taipe@gmail.com'),
('45001012','Cesar Augusto','Palomino Cruz','911001012','cesar.palomino@gmail.com'),
('45001013','Giovanna Isabel','Huayta Mamani','911001013','giovanna.huayta@gmail.com'),
('45001014','Alvaro Nicolas','Zarate Campos','911001014','alvaro.zarate@gmail.com'),
('45001015','Claudia Patricia','Soto Berrios','911001015','claudia.soto@gmail.com');

-- BOLETOS (30) — tabla transaccional
INSERT INTO tv.boleto (id_viaje,id_pasajero,id_empleado,nro_asiento,precio,estado) VALUES
(1,1,3,5,75.00,'usado'),
(1,2,3,12,75.00,'usado'),
(1,3,4,18,75.00,'usado'),
(2,4,3,1,200.00,'usado'),
(2,5,4,2,200.00,'usado'),
(3,6,5,8,45.00,'usado'),
(3,7,5,15,45.00,'usado'),
(4,8,8,3,130.00,'usado'),
(4,9,8,10,130.00,'usado'),
(4,10,3,22,130.00,'usado'),
(5,11,4,1,30.00,'usado'),
(5,12,4,5,30.00,'usado'),
(6,1,5,7,120.00,'usado'),
(6,2,8,14,120.00,'usado'),
(7,3,3,2,25.00,'usado'),
(7,4,3,6,25.00,'usado'),
(8,5,4,9,75.00,'usado'),
(8,6,4,20,75.00,'usado'),
(9,7,5,11,55.00,'usado'),
(9,8,8,25,55.00,'usado'),
(10,9,3,4,210.00,'usado'),
(10,10,3,16,210.00,'usado'),
(11,11,4,8,150.00,'usado'),
(11,12,5,30,150.00,'usado'),
(12,13,8,3,30.00,'usado'),
(13,14,3,1,160.00,'activo'),
(13,15,4,19,160.00,'activo'),
(16,1,5,10,170.00,'activo'),
(17,2,8,4,25.00,'activo'),
(19,3,3,22,100.00,'activo');

-- ENCOMIENDAS (20) — tabla transaccional
INSERT INTO tv.encomienda (id_viaje,dni_remitente,nombre_remitente,dni_destinatario,nombre_destinatario,descripcion,peso_kg,precio,estado_actual) VALUES
(1,'45001001','Carla Mendoza','45002001','Luis Flores','Ropa y calzado',5.50,22.00,'ENTREGADO'),
(1,'45001002','Andres Salazar','45002002','Marta Quispe','Libros universitarios',8.00,28.00,'ENTREGADO'),
(2,'45001003','Paola Vega','45002003','Rocio Mamani','Medicamentos',2.20,15.00,'ENTREGADO'),
(3,'45001004','Gonzalo Ramos','45002004','Pedro Condori','Repuestos electronicos',4.80,25.00,'ENTREGADO'),
(4,'45001005','Valeria Nunez','45002005','Ana Huanca','Viveres y conservas',12.00,40.00,'ENTREGADO'),
(5,'45001006','Jose Benites','45002006','Carlos Apaza','Herramientas de trabajo',7.30,30.00,'ENTREGADO'),
(6,'45001007','Natalia Condor','45002007','Jorge Quispe','Artesania y tejidos',3.50,18.00,'ENTREGADO'),
(7,'45001008','Ricardo Poma','45002008','Sandra Turpo','Electrodomestico pequeno',6.00,32.00,'ENTREGADO'),
(8,'45001009','Diana Cervantes','45002009','Miguel Ccopa','Documentos y papeleria',1.00,10.00,'ENTREGADO'),
(9,'45001010','Fernando Aquino','45002010','Rosa Lazo','Juguetes',5.00,20.00,'ENTREGADO'),
(10,'45001011','Milagros Taipe','45002011','Hugo Flores','Ropa de temporada',9.50,35.00,'ENTREGADO'),
(11,'45001012','Cesar Palomino','45002012','Elena Torres','Material de construccion',20.00,60.00,'ENTREGADO'),
(12,'45001013','Giovanna Huayta','45002013','Luis Choque','Alimentos procesados',6.80,27.00,'ENTREGADO'),
(13,'45001014','Alvaro Zarate','45002014','Carmen Nina','Muestras comerciales',3.00,18.00,'EN_TRANSITO'),
(14,'45001015','Claudia Soto','45002015','Pedro Hancco','Cosmeticos y perfumeria',2.50,15.00,'EN_TRANSITO'),
(15,'45001001','Carla Mendoza','45002016','Ana Paredes','Equipos de oficina',15.00,55.00,'EN_TRANSITO'),
(16,'45001002','Andres Salazar','45002017','Jose Bautista','Ropa deportiva',4.20,22.00,'REGISTRADO'),
(17,'45001003','Paola Vega','45002018','Maria Asto','Instrumentos musicales',7.00,38.00,'REGISTRADO'),
(18,'45001004','Gonzalo Ramos','45002019','Carlos Ore','Productos agricolas',25.00,70.00,'REGISTRADO'),
(19,'45001005','Valeria Nunez','45002020','Sandra Sulca','Bisuteria y accesorios',1.80,12.00,'REGISTRADO');

-- HISTORIAL ESTADOS ENCOMIENDA
INSERT INTO tv.estado_encomienda (id_encomienda,estado,observacion) VALUES
(1,'REGISTRADO','Encomienda recibida en terminal Lima'),
(1,'EN_TRANSITO','Vehiculo en ruta Lima-Arequipa'),
(1,'ENTREGADO','Entregada al destinatario en Arequipa'),
(2,'REGISTRADO','Encomienda recibida en terminal Lima'),
(2,'EN_TRANSITO','Vehiculo en ruta'),
(2,'ENTREGADO','Entregada sin inconvenientes'),
(14,'REGISTRADO','Encomienda recibida en terminal Lima'),
(14,'EN_TRANSITO','Vehiculo en ruta Lima-Arequipa'),
(16,'REGISTRADO','Encomienda registrada'),
(16,'EN_TRANSITO','Salio en viaje 15'),
(17,'REGISTRADO','Encomienda recibida, pendiente de despacho'),
(18,'REGISTRADO','Encomienda registrada en sistema');

-- PAGOS DE BOLETOS (30)
INSERT INTO tv.pago (id_boleto,monto,metodo_pago) VALUES
(1,75.00,'EFECTIVO'),(2,75.00,'YAPE'),(3,75.00,'EFECTIVO'),
(4,200.00,'TARJETA'),(5,200.00,'TARJETA'),(6,45.00,'EFECTIVO'),
(7,45.00,'PLIN'),(8,130.00,'TRANSFERENCIA'),(9,130.00,'TARJETA'),
(10,130.00,'YAPE'),(11,30.00,'EFECTIVO'),(12,30.00,'EFECTIVO'),
(13,120.00,'TARJETA'),(14,120.00,'YAPE'),(15,25.00,'EFECTIVO'),
(16,25.00,'EFECTIVO'),(17,75.00,'PLIN'),(18,75.00,'TRANSFERENCIA'),
(19,55.00,'EFECTIVO'),(20,55.00,'YAPE'),(21,210.00,'TARJETA'),
(22,210.00,'TARJETA'),(23,150.00,'TRANSFERENCIA'),(24,150.00,'YAPE'),
(25,30.00,'EFECTIVO'),(26,160.00,'TARJETA'),(27,160.00,'TARJETA'),
(28,170.00,'YAPE'),(29,25.00,'EFECTIVO'),(30,100.00,'EFECTIVO');

-- PAGOS DE ENCOMIENDAS (15)
INSERT INTO tv.pago (id_encomienda,monto,metodo_pago) VALUES
(1,22.00,'EFECTIVO'),(2,28.00,'YAPE'),(3,15.00,'EFECTIVO'),
(4,25.00,'PLIN'),(5,40.00,'TARJETA'),(6,30.00,'EFECTIVO'),
(7,18.00,'YAPE'),(8,32.00,'TRANSFERENCIA'),(9,10.00,'EFECTIVO'),
(10,20.00,'EFECTIVO'),(11,35.00,'TARJETA'),(12,60.00,'TARJETA'),
(13,27.00,'YAPE'),(14,18.00,'EFECTIVO'),(15,15.00,'PLIN');

-- MANTENIMIENTOS (12)
INSERT INTO tv.mantenimiento (id_vehiculo,tipo,descripcion,fecha_inicio,fecha_fin,costo,estado) VALUES
(1,'PREVENTIVO','Cambio de aceite y filtros','2026-04-10','2026-04-10',350.00,'completado'),
(2,'PREVENTIVO','Revision de frenos y neumaticos','2026-04-15','2026-04-16',520.00,'completado'),
(3,'CORRECTIVO','Reparacion del sistema de enfriamiento','2026-05-01','2026-05-03',1200.00,'completado'),
(4,'PREVENTIVO','Alineamiento y balanceo','2026-05-10','2026-05-10',180.00,'completado'),
(5,'PREVENTIVO','Cambio de aceite y filtros','2026-05-20','2026-05-20',350.00,'completado'),
(6,'CORRECTIVO','Cambio de parabrisas','2026-05-25','2026-05-26',800.00,'completado'),
(7,'PREVENTIVO','Revision general 50000 km','2026-06-01','2026-06-02',950.00,'completado'),
(8,'PREVENTIVO','Cambio de aceite y filtros','2026-06-05','2026-06-05',350.00,'completado'),
(9,'CORRECTIVO','Reparacion de caja de cambios','2026-06-08','2026-06-12',3500.00,'completado'),
(10,'CORRECTIVO','Falla en el sistema electrico','2026-06-14',NULL,NULL,'en_proceso'),
(11,'PREVENTIVO','Revision de neumaticos y suspension','2026-06-18','2026-06-18',420.00,'completado'),
(12,'PREVENTIVO','Cambio de aceite y filtros','2026-06-20',NULL,NULL,'pendiente');

-- ============================================================
-- SECCIÓN 5: CONSULTAS SQL OBLIGATORIAS (20 en total)
-- ============================================================

-- == CONSULTAS BÁSICAS (5) ==

-- CB01: Conductores activos con estado de licencia
SELECT dni, nombres||' '||apellidos AS conductor, tipo_licencia, fecha_venc_lic,
    CASE
        WHEN fecha_venc_lic < CURRENT_DATE THEN 'VENCIDA'
        WHEN fecha_venc_lic < CURRENT_DATE + INTERVAL '90 days' THEN 'POR VENCER'
        ELSE 'VIGENTE'
    END AS estado_licencia
FROM tv.conductor WHERE estado = TRUE ORDER BY fecha_venc_lic;

-- CB02: Vehículos operativos por capacidad descendente
SELECT placa, tipo, marca||' '||modelo AS vehiculo, anio, capacidad
FROM tv.vehiculo WHERE estado = 'operativo' ORDER BY capacidad DESC;

-- CB03: Viajes desde Lima con duración mayor a 10 horas
SELECT v.id_viaje, r.ciudad_origen, r.ciudad_destino, r.duracion_horas,
       v.fecha_salida, v.tipo_servicio
FROM tv.viaje v INNER JOIN tv.ruta r ON v.id_ruta = r.id_ruta
WHERE r.ciudad_origen = 'Lima' AND r.duracion_horas > 10
  AND v.estado IN ('programado','en_curso') ORDER BY v.fecha_salida;

-- CB04: Pasajeros con correo que viajaron en CAMA (DISTINCT)
SELECT DISTINCT p.dni, p.nombres||' '||p.apellidos AS pasajero, p.correo
FROM tv.pasajero p
INNER JOIN tv.boleto b ON p.id_pasajero = b.id_pasajero
INNER JOIN tv.viaje  v ON b.id_viaje    = v.id_viaje
WHERE p.correo IS NOT NULL AND v.tipo_servicio = 'CAMA' ORDER BY p.apellidos;

-- CB05: Encomiendas entre 5 y 15 kg pendientes (BETWEEN + IN)
SELECT e.id_encomienda, e.nombre_remitente, e.descripcion, e.peso_kg,
       e.estado_actual, r.ciudad_origen||' -> '||r.ciudad_destino AS ruta
FROM tv.encomienda e
INNER JOIN tv.viaje v ON e.id_viaje = v.id_viaje
INNER JOIN tv.ruta  r ON v.id_ruta  = r.id_ruta
WHERE e.peso_kg BETWEEN 5 AND 15 AND e.estado_actual IN ('REGISTRADO','EN_TRANSITO')
ORDER BY e.peso_kg DESC;

-- == CONSULTAS CON JOIN (5) ==

-- CJ01: Detalle completo de boletos (INNER JOIN 4 tablas)
SELECT b.id_boleto, p.nombres||' '||p.apellidos AS pasajero,
       r.ciudad_origen||' -> '||r.ciudad_destino AS ruta,
       v.fecha_salida, v.tipo_servicio, b.nro_asiento, b.precio, b.estado
FROM tv.boleto b
INNER JOIN tv.pasajero p ON b.id_pasajero = p.id_pasajero
INNER JOIN tv.viaje    v ON b.id_viaje    = v.id_viaje
INNER JOIN tv.ruta     r ON v.id_ruta     = r.id_ruta
ORDER BY v.fecha_salida, b.nro_asiento;

-- CJ02: Todos los viajes con conductor y vehículo (LEFT JOIN)
SELECT v.id_viaje, r.ciudad_origen||' -> '||r.ciudad_destino AS ruta,
       v.fecha_salida, v.estado,
       c.nombres||' '||c.apellidos AS conductor, c.tipo_licencia,
       ve.placa, ve.tipo AS tipo_vehiculo, ve.capacidad
FROM tv.viaje v
INNER JOIN tv.ruta      r  ON v.id_ruta      = r.id_ruta
LEFT  JOIN tv.conductor c  ON v.id_conductor = c.id_conductor
LEFT  JOIN tv.vehiculo  ve ON v.id_vehiculo  = ve.id_vehiculo
ORDER BY v.fecha_salida;

-- CJ03: Ingresos por viaje sumando boletos y encomiendas
SELECT v.id_viaje, r.ciudad_origen||' -> '||r.ciudad_destino AS ruta,
       v.fecha_salida, v.tipo_servicio,
       COALESCE((SELECT SUM(b2.precio) FROM tv.boleto b2
                 WHERE b2.id_viaje = v.id_viaje AND b2.estado <> 'cancelado'),0) AS ing_boletos,
       COALESCE((SELECT SUM(e2.precio) FROM tv.encomienda e2
                 WHERE e2.id_viaje = v.id_viaje),0) AS ing_encomiendas
FROM tv.viaje v INNER JOIN tv.ruta r ON v.id_ruta = r.id_ruta
ORDER BY v.fecha_salida;

-- CJ04: Historial de pagos con tipo y cliente
SELECT pg.id_pago, pg.fecha_pago, pg.monto, pg.metodo_pago,
    CASE WHEN pg.id_boleto IS NOT NULL THEN 'BOLETO' ELSE 'ENCOMIENDA' END AS tipo_pago,
    COALESCE(ps.nombres||' '||ps.apellidos, enc.nombre_remitente) AS cliente
FROM tv.pago pg
LEFT JOIN tv.boleto     b   ON pg.id_boleto     = b.id_boleto
LEFT JOIN tv.pasajero   ps  ON b.id_pasajero    = ps.id_pasajero
LEFT JOIN tv.encomienda enc ON pg.id_encomienda = enc.id_encomienda
ORDER BY pg.fecha_pago DESC;

-- CJ05: Vehículos con sus mantenimientos (LEFT JOIN — muestra todos)
SELECT ve.placa, ve.tipo, ve.marca||' '||ve.modelo AS vehiculo, ve.estado,
       m.tipo AS tipo_mant, m.descripcion, m.fecha_inicio, m.costo, m.estado AS est_mant
FROM tv.vehiculo ve
LEFT JOIN tv.mantenimiento m ON m.id_vehiculo = ve.id_vehiculo
ORDER BY ve.placa, m.fecha_inicio DESC;

-- == FUNCIONES AGREGADAS (4) ==

-- FA01: Ingresos por ruta con COUNT, SUM, AVG, MIN, MAX
SELECT r.ciudad_origen||' -> '||r.ciudad_destino AS ruta,
       COUNT(b.id_boleto) AS total_boletos, SUM(b.precio) AS ingresos_totales,
       AVG(b.precio) AS precio_promedio, MIN(b.precio) AS minimo, MAX(b.precio) AS maximo
FROM tv.ruta r
INNER JOIN tv.viaje  v ON v.id_ruta  = r.id_ruta
INNER JOIN tv.boleto b ON b.id_viaje = v.id_viaje
WHERE b.estado <> 'cancelado'
GROUP BY r.id_ruta, r.ciudad_origen, r.ciudad_destino ORDER BY ingresos_totales DESC;

-- FA02: Pasajeros con mayor gasto total (GROUP BY + HAVING)
SELECT p.dni, p.nombres||' '||p.apellidos AS pasajero,
       COUNT(b.id_boleto) AS total_boletos, SUM(b.precio) AS gasto_total
FROM tv.pasajero p INNER JOIN tv.boleto b ON b.id_pasajero = p.id_pasajero
GROUP BY p.id_pasajero, p.dni, p.nombres, p.apellidos
HAVING COUNT(b.id_boleto) >= 1
ORDER BY gasto_total DESC;

-- FA03: Ingresos mensuales por método de pago
SELECT EXTRACT(YEAR FROM fecha_pago) AS anio,
       EXTRACT(MONTH FROM fecha_pago) AS mes,
       metodo_pago, COUNT(*) AS transacciones, SUM(monto) AS total_recaudado
FROM tv.pago WHERE estado = 'PAGADO'
GROUP BY anio, mes, metodo_pago HAVING SUM(monto) > 0
ORDER BY anio, mes, total_recaudado DESC;

-- FA04: Encomiendas por ruta con peso promedio e ingresos
SELECT r.ciudad_origen||' -> '||r.ciudad_destino AS ruta,
       COUNT(e.id_encomienda) AS total_enc,
       ROUND(AVG(e.peso_kg),2) AS peso_prom_kg, SUM(e.peso_kg) AS peso_total,
       SUM(e.precio) AS ingresos_encomiendas
FROM tv.ruta r
INNER JOIN tv.viaje      v ON v.id_ruta  = r.id_ruta
INNER JOIN tv.encomienda e ON e.id_viaje = v.id_viaje
GROUP BY r.id_ruta, r.ciudad_origen, r.ciudad_destino
ORDER BY ingresos_encomiendas DESC;

-- == SUBCONSULTAS (3) ==

-- SC01: Conductores con viajes iguales o mayores al promedio (IN)
SELECT c.dni, c.nombres||' '||c.apellidos AS conductor,
       c.tipo_licencia, COUNT(v.id_viaje) AS total_viajes
FROM tv.conductor c INNER JOIN tv.viaje v ON v.id_conductor = c.id_conductor
WHERE c.id_conductor IN (
    SELECT id_conductor FROM tv.viaje GROUP BY id_conductor
    HAVING COUNT(*) >= (SELECT AVG(cnt) FROM
        (SELECT COUNT(*) AS cnt FROM tv.viaje GROUP BY id_conductor) t)
)
GROUP BY c.id_conductor, c.dni, c.nombres, c.apellidos, c.tipo_licencia
ORDER BY total_viajes DESC;

-- SC02: Viajes con encomiendas pendientes (EXISTS)
SELECT v.id_viaje, r.ciudad_origen||' -> '||r.ciudad_destino AS ruta,
       v.fecha_salida, v.estado
FROM tv.viaje v INNER JOIN tv.ruta r ON v.id_ruta = r.id_ruta
WHERE EXISTS (
    SELECT 1 FROM tv.encomienda e
    WHERE e.id_viaje = v.id_viaje AND e.estado_actual IN ('REGISTRADO','EN_TRANSITO')
);

-- SC03: Pasajeros que pagaron más que el promedio de su ruta (subconsulta correlacionada)
SELECT p.nombres||' '||p.apellidos AS pasajero,
       r.ciudad_origen||' -> '||r.ciudad_destino AS ruta,
       b.precio AS pagado,
       (SELECT ROUND(AVG(b2.precio),2) FROM tv.boleto b2
        INNER JOIN tv.viaje v2 ON b2.id_viaje = v2.id_viaje
        WHERE v2.id_ruta = v.id_ruta AND b2.estado <> 'cancelado') AS promedio_ruta
FROM tv.boleto b
INNER JOIN tv.pasajero p ON b.id_pasajero = p.id_pasajero
INNER JOIN tv.viaje    v ON b.id_viaje    = v.id_viaje
INNER JOIN tv.ruta     r ON v.id_ruta     = r.id_ruta
WHERE b.precio > (
    SELECT AVG(b2.precio) FROM tv.boleto b2
    INNER JOIN tv.viaje v2 ON b2.id_viaje = v2.id_viaje
    WHERE v2.id_ruta = v.id_ruta AND b2.estado <> 'cancelado')
ORDER BY r.ciudad_destino, b.precio DESC;

-- == FUNCIONES DE FECHA, CADENA Y CONVERSIÓN (3) ==

-- FD01: Edad de conductores y días para vencimiento de licencia
SELECT nombres||' '||apellidos AS conductor, fecha_nac,
       AGE(CURRENT_DATE, fecha_nac) AS edad,
       fecha_venc_lic - CURRENT_DATE AS dias_vencimiento,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, fecha_nac)) AS anios
FROM tv.conductor WHERE estado = TRUE ORDER BY dias_vencimiento;

-- FD02: Duración real de viajes completados con ruta en mayúsculas
SELECT v.id_viaje,
       UPPER(r.ciudad_origen)||' -> '||UPPER(r.ciudad_destino) AS ruta,
       v.fecha_salida, v.fecha_llegada_est,
       EXTRACT(EPOCH FROM (v.fecha_llegada_est - v.fecha_salida))/3600 AS horas_est
FROM tv.viaje v INNER JOIN tv.ruta r ON v.id_ruta = r.id_ruta
WHERE v.estado = 'completado' ORDER BY v.fecha_salida;

-- FD03: Reporte de pagos con monto formateado, CAST y SUBSTRING
SELECT pg.id_pago,
       TO_CHAR(pg.fecha_pago,'DD/MM/YYYY HH24:MI') AS fecha_hora,
       CASE WHEN pg.id_boleto IS NOT NULL
            THEN 'Boleto #'||CAST(pg.id_boleto AS VARCHAR)
            ELSE 'Encomienda #'||CAST(pg.id_encomienda AS VARCHAR) END AS concepto,
       LOWER(pg.metodo_pago) AS metodo,
       'S/. '||TO_CHAR(pg.monto,'FM999,990.00') AS monto_fmt,
       SUBSTRING(pg.estado FROM 1 FOR 3) AS est_abrev
FROM tv.pago pg
WHERE EXTRACT(MONTH FROM pg.fecha_pago) = EXTRACT(MONTH FROM CURRENT_DATE)
ORDER BY pg.fecha_pago DESC;

-- ============================================================
-- SECCIÓN 6: VISTAS (4)
-- ============================================================

CREATE OR REPLACE VIEW tv.v_disponibilidad_viaje AS
SELECT v.id_viaje, r.ciudad_origen||' -> '||r.ciudad_destino AS ruta,
       v.fecha_salida, v.tipo_servicio, ve.placa, ve.capacidad,
       COUNT(b.id_boleto) AS vendidos,
       ve.capacidad - COUNT(b.id_boleto) AS disponibles,
       ROUND(COUNT(b.id_boleto)*100.0/ve.capacidad,1) AS pct_ocupacion
FROM tv.viaje v
INNER JOIN tv.ruta     r  ON v.id_ruta     = r.id_ruta
INNER JOIN tv.vehiculo ve ON v.id_vehiculo = ve.id_vehiculo
LEFT  JOIN tv.boleto   b  ON b.id_viaje    = v.id_viaje AND b.estado <> 'cancelado'
GROUP BY v.id_viaje, r.ciudad_origen, r.ciudad_destino,
         v.fecha_salida, v.tipo_servicio, ve.placa, ve.capacidad;

CREATE OR REPLACE VIEW tv.v_ingresos_por_ruta AS
SELECT r.id_ruta, r.ciudad_origen||' -> '||r.ciudad_destino AS ruta, r.distancia_km,
       COALESCE(SUM(b.precio),0) AS ing_boletos,
       COALESCE(SUM(e.precio),0) AS ing_encomiendas,
       COALESCE(SUM(b.precio),0)+COALESCE(SUM(e.precio),0) AS ing_total,
       COUNT(DISTINCT v.id_viaje) AS total_viajes
FROM tv.ruta r
LEFT JOIN tv.viaje      v ON v.id_ruta  = r.id_ruta
LEFT JOIN tv.boleto     b ON b.id_viaje = v.id_viaje AND b.estado <> 'cancelado'
LEFT JOIN tv.encomienda e ON e.id_viaje = v.id_viaje
GROUP BY r.id_ruta, r.ciudad_origen, r.ciudad_destino, r.distancia_km;

CREATE OR REPLACE VIEW tv.v_encomiendas_pendientes AS
SELECT e.id_encomienda, e.nombre_remitente, e.nombre_destinatario,
       e.descripcion, e.peso_kg, e.estado_actual,
       r.ciudad_origen||' -> '||r.ciudad_destino AS ruta, v.fecha_salida, v.estado
FROM tv.encomienda e
INNER JOIN tv.viaje v ON e.id_viaje = v.id_viaje
INNER JOIN tv.ruta  r ON v.id_ruta  = r.id_ruta
WHERE e.estado_actual IN ('REGISTRADO','EN_TRANSITO') ORDER BY v.fecha_salida;

CREATE OR REPLACE VIEW tv.v_panel_dia AS
SELECT
    (SELECT COUNT(*) FROM tv.viaje      WHERE DATE(fecha_salida) = CURRENT_DATE) AS viajes_hoy,
    (SELECT COUNT(*) FROM tv.boleto     WHERE DATE(fecha_venta)  = CURRENT_DATE) AS boletos_hoy,
    (SELECT COALESCE(SUM(monto),0) FROM tv.pago WHERE DATE(fecha_pago)=CURRENT_DATE AND estado='PAGADO') AS recaudacion_hoy,
    (SELECT COUNT(*) FROM tv.vehiculo   WHERE estado = 'mantenimiento')           AS vehiculos_mant,
    (SELECT COUNT(*) FROM tv.encomienda WHERE estado_actual IN ('REGISTRADO','EN_TRANSITO')) AS enc_pendientes;

-- ============================================================
-- SECCIÓN 7: FUNCIONES (2)
-- ============================================================

CREATE OR REPLACE FUNCTION tv.fn_total_pagado_pasajero(p_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(pg.monto),0) INTO v_total
    FROM tv.pago pg INNER JOIN tv.boleto b ON pg.id_boleto = b.id_boleto
    WHERE b.id_pasajero = p_id AND pg.estado = 'PAGADO';
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;
-- SELECT tv.fn_total_pagado_pasajero(1);

CREATE OR REPLACE FUNCTION tv.fn_asientos_disponibles(p_id_viaje INTEGER)
RETURNS INTEGER AS $$
DECLARE v_cap INTEGER; v_vend INTEGER;
BEGIN
    SELECT ve.capacidad INTO v_cap
    FROM tv.viaje v INNER JOIN tv.vehiculo ve ON v.id_vehiculo = ve.id_vehiculo
    WHERE v.id_viaje = p_id_viaje;
    SELECT COUNT(*) INTO v_vend FROM tv.boleto
    WHERE id_viaje = p_id_viaje AND estado <> 'cancelado';
    RETURN v_cap - v_vend;
END;
$$ LANGUAGE plpgsql;
-- SELECT tv.fn_asientos_disponibles(1);

-- ============================================================
-- SECCIÓN 8: PROCEDIMIENTOS ALMACENADOS (2)
-- ============================================================

CREATE OR REPLACE PROCEDURE tv.sp_registrar_boleto(
    p_id_viaje INTEGER, p_id_pasajero INTEGER, p_id_empleado INTEGER,
    p_nro_asiento SMALLINT, p_precio NUMERIC, p_metodo VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_id_boleto INTEGER; v_disp INTEGER;
BEGIN
    v_disp := tv.fn_asientos_disponibles(p_id_viaje);
    IF v_disp <= 0 THEN
        RAISE EXCEPTION 'Sin asientos disponibles en viaje %', p_id_viaje;
    END IF;
    INSERT INTO tv.boleto (id_viaje,id_pasajero,id_empleado,nro_asiento,precio)
    VALUES (p_id_viaje,p_id_pasajero,p_id_empleado,p_nro_asiento,p_precio)
    RETURNING id_boleto INTO v_id_boleto;
    INSERT INTO tv.pago (id_boleto,monto,metodo_pago) VALUES (v_id_boleto,p_precio,p_metodo);
    RAISE NOTICE 'Boleto % registrado y pago procesado.', v_id_boleto;
END;
$$;
-- CALL tv.sp_registrar_boleto(20,5,3,8::SMALLINT,120.00,'YAPE');

CREATE OR REPLACE PROCEDURE tv.sp_registrar_encomienda(
    p_id_viaje INTEGER, p_dni_rem CHAR, p_nom_rem VARCHAR,
    p_dni_dest CHAR, p_nom_dest VARCHAR,
    p_desc VARCHAR, p_peso NUMERIC, p_precio NUMERIC, p_metodo VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_id INTEGER;
BEGIN
    IF p_dni_rem = p_dni_dest THEN
        RAISE EXCEPTION 'Remitente y destinatario no pueden ser la misma persona.';
    END IF;
    INSERT INTO tv.encomienda
        (id_viaje,dni_remitente,nombre_remitente,dni_destinatario,nombre_destinatario,descripcion,peso_kg,precio)
    VALUES (p_id_viaje,p_dni_rem,p_nom_rem,p_dni_dest,p_nom_dest,p_desc,p_peso,p_precio)
    RETURNING id_encomienda INTO v_id;
    INSERT INTO tv.estado_encomienda (id_encomienda,estado,observacion)
    VALUES (v_id,'REGISTRADO','Encomienda recibida en terminal');
    INSERT INTO tv.pago (id_encomienda,monto,metodo_pago) VALUES (v_id,p_precio,p_metodo);
    RAISE NOTICE 'Encomienda % registrada.', v_id;
END;
$$;

-- ============================================================
-- SECCIÓN 9: TRIGGERS (2)
-- ============================================================

-- TRIGGER 1: Validar capacidad antes de insertar boleto
CREATE OR REPLACE FUNCTION tv.trg_fn_validar_capacidad()
RETURNS TRIGGER AS $$
BEGIN
    IF tv.fn_asientos_disponibles(NEW.id_viaje) <= 0 THEN
        RAISE EXCEPTION 'Capacidad maxima alcanzada para viaje %.', NEW.id_viaje;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_capacidad
BEFORE INSERT ON tv.boleto
FOR EACH ROW EXECUTE FUNCTION tv.trg_fn_validar_capacidad();

-- TRIGGER 2: Cambiar estado del vehículo según mantenimiento
CREATE OR REPLACE FUNCTION tv.trg_fn_estado_vehiculo()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'en_proceso' THEN
        UPDATE tv.vehiculo SET estado = 'mantenimiento' WHERE id_vehiculo = NEW.id_vehiculo;
    ELSIF NEW.estado = 'completado' THEN
        UPDATE tv.vehiculo SET estado = 'operativo' WHERE id_vehiculo = NEW.id_vehiculo;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_estado_vehiculo
AFTER INSERT OR UPDATE ON tv.mantenimiento
FOR EACH ROW EXECUTE FUNCTION tv.trg_fn_estado_vehiculo();

-- ============================================================
-- SECCIÓN 10: TRANSACCIONES (2)
-- ============================================================

-- TRANSACCIÓN 1: Registro exitoso con COMMIT
BEGIN;
    INSERT INTO tv.boleto (id_viaje,id_pasajero,id_empleado,nro_asiento,precio)
    VALUES (20,14,3,30,120.00);
    INSERT INTO tv.pago (id_boleto,monto,metodo_pago)
    VALUES (currval('tv.boleto_id_boleto_seq'),120.00,'YAPE');
COMMIT;

-- TRANSACCIÓN 2: Caso con ROLLBACK (error controlado)
BEGIN;
    -- Intento de actualizar un boleto inexistente
    UPDATE tv.boleto SET estado = 'cancelado' WHERE id_boleto = 9999;
    -- En una app real se lanzaría excepción aquí si rowcount = 0
    -- Simulamos el ROLLBACK para revertir la operación:
ROLLBACK;

-- ============================================================
-- SECCIÓN 11: SEGURIDAD — ROLES Y PERMISOS
-- ============================================================

CREATE ROLE rol_admin_tv;
CREATE ROLE rol_operador_tv;
CREATE ROLE rol_consulta_tv;

CREATE USER usr_admin_tv    WITH PASSWORD 'Admin#2026!'  IN ROLE rol_admin_tv;
CREATE USER usr_operador_tv WITH PASSWORD 'Oper#2026!'   IN ROLE rol_operador_tv;
CREATE USER usr_consulta_tv WITH PASSWORD 'Cons#2026!'   IN ROLE rol_consulta_tv;

-- Administrador: acceso total
GRANT ALL PRIVILEGES ON SCHEMA tv TO rol_admin_tv;
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA tv TO rol_admin_tv;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA tv TO rol_admin_tv;

-- Operador: lectura + escritura, sin DELETE
GRANT USAGE ON SCHEMA tv TO rol_operador_tv;
GRANT SELECT, INSERT, UPDATE ON tv.conductor, tv.vehiculo, tv.viaje,
      tv.boleto, tv.encomienda, tv.estado_encomienda TO rol_operador_tv;
GRANT SELECT, INSERT ON tv.pago TO rol_operador_tv;
GRANT SELECT ON tv.ruta, tv.tarifa, tv.pasajero, tv.empleado TO rol_operador_tv;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA tv TO rol_operador_tv;
REVOKE DELETE ON ALL TABLES IN SCHEMA tv FROM rol_operador_tv;

-- Consulta: solo lectura
GRANT USAGE  ON SCHEMA tv TO rol_consulta_tv;
GRANT SELECT ON ALL TABLES IN SCHEMA tv TO rol_consulta_tv;

-- ============================================================
-- SECCIÓN 12: BACKUP Y RESTAURACIÓN
-- ============================================================
-- Ejecutar en terminal del sistema operativo (no en psql):
--
-- Generar backup completo:
-- pg_dump -U postgres -d bd_transvias -f backup_transvias_20260622.sql
--
-- Restaurar backup:
-- psql -U postgres -d bd_transvias -f backup_transvias_20260622.sql
--
-- Backup solo del esquema tv:
-- pg_dump -U postgres -d bd_transvias -n tv -f backup_esquema_tv.sql

-- ============================================================
-- FIN DEL SCRIPT — TransVías S.A.C. — BD 100000SI33
-- ============================================================
