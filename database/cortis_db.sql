CREATE TABLE COERS (
	ID SERIAL PRIMARY KEY,
	nome VARCHAR(50) NOT NULL,
	email VARCHAR(100) UNIQUE NOT NULL,
	senha VARCHAR (100) NOT NULL,
	data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	nivel_filiacao VARCHAR (20) default 'bronze'
);

create table orders (
	id serial primary key,
	coer_id varchar (100) not null,
	data_orders timestamp default current_timestamp,
	total_orders decimal (10,2) not null,
	status varchar (30) default 'pendente'
)


