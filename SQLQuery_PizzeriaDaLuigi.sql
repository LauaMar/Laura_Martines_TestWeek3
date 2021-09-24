/** CREAZIONE DB E TABELLE**/

--Create Database PizzeriaDaLuigi

Create Table Pizza (
CodicePizza int identity(1,1) not null primary key,
NomePizza nvarchar(40) not null unique, 
Prezzo decimal(4,2) not null
Constraint CK_PrezzoPizza check (Prezzo>0),
)

create table Ingrediente(
CodiceIngrediente int identity(1,1) not null primary key,
NomeIngrediente nvarchar(40) not null unique,
Costo decimal(4,2) not null,
Scorta integer not null,
Constraint CK_CostoIngrediente check (Costo>0),
Constraint CK_ScortaIngrediente check (Scorta>=0)
)

create Table IngredientePizza(
CodiceIngrediente int not null,
CodicePizza int not null,
Constraint FK_IngredientePizza_Ingrediente foreign key (CodiceIngrediente) references Ingrediente(CodiceIngrediente),
Constraint FK_IngredientePizza_Pizza foreign key (CodicePizza) references Pizza(CodicePizza),
Constraint PK_IngredientePIzza primary key (CodiceIngrediente, CodicePizza)
)

/**INSERIMENTO DATI**/

--Insert into Pizza values ('Margherita',5),('Bufala',7),('Diavola',6),('Quattro Stagioni',6.5),('Porcini',7),
--('Dioniso',8),('Ortolana',8),('Patate e salsiccia',6),('Pomodorini',6),('Quattro formaggi',7.5),('Caprese',7.5),
--('Zeus',7.5)

--Insert into Ingrediente values ('pomodoro',1.5,2500),('mozzarella',0.5,500),('mozzarella di bufala',1,250),
--('spianata piccante',5,150),('funghi',3.5,500),('carciofi',5,350),('cotto',10,300),('olive',4.5,10),
--('funghi porcini',20,150),('stracchino',1.75,200),('speck',10,300),('rucola',2.5,100),('grana',25,300),
--('verdure di stagione',4.25,400),('patate',2.5,200),('salsiccia',7.5,200),('pomodorini',5.5,200),
--('ricotta',6.70,150),('provola',3.5,150),('gorgonzola',5.5,300),('pomodoro fresco',2.75,300),('basilico',1.50,1),
--('bresaola',10.5,150)

--insert into IngredientePizza values(1,1),(2,1),(1,2),(3,2),(1,3),(2,3),(4,3),(1,4),(2,4),(5,4),(6,4),(7,4),(8,4),(1,5),
--(2,5),(9,5),(1,6),(2,6),(10,6),(11,6),(12,6),(13,6),(1,7),(2,7),(14,7),(2,8),(15,8),(16,8),(2,9),(17,9),(18,9),
--(2,10),(13,10),(19,10),(20,10),(2,11),(21,11),(22,11),(2,12),(12,12),(23,12)

/**QUERY**/

--1. Estrarre tutte le pizze con prezzo superiore a 6 euro
select *
from Pizza p
where p.Prezzo>6

--2. Estrarre la pizza più costosa
select * 
from Pizza p
where p.Prezzo >= all (select p.Prezzo
					   from Pizza p)

--3. Estrarre le pizze "bianche"
select *
from Pizza p 
where p.NomePizza not in (select p.NomePizza
						  from Pizza p join IngredientePizza Ipi on p.CodicePizza=Ipi.CodicePizza
									   join Ingrediente i on Ipi.CodiceIngrediente=i.CodiceIngrediente
						  where i.NomeIngrediente='pomodoro')

--4. Estrarre le pizze che contengono funghi (di qualsiasi tipo)

select p.*
from Pizza p join IngredientePizza Ipi on p.CodicePizza=Ipi.CodicePizza
			 join Ingrediente i on Ipi.CodiceIngrediente=i.CodiceIngrediente
where i.NomeIngrediente like '%funghi%'

/** PROCEDURE **/

-- 1. Inserimento di una nuova pizza (parametri: nome, prezzo)

create procedure InserisciNuovaPizza
@nome nvarchar(40),
@prezzo decimal(4,2)
AS
Begin
	begin try
	insert into Pizza values (@nome, @prezzo)
	end try
	begin catch
	select ERROR_MESSAGE(), ERROR_LINE()
	end catch
end
					
execute InserisciNuovaPizza 'Cotto e funghi', 6.5

--2. Assegnazione di un ingrediente a una pizza (parametri: nome pizza, nome ingrediente)

create procedure AssegnaIngredienteAPizza
@nomeIngrediente nvarchar(40),
@nomePizza nvarchar(40)
AS
Begin
	begin try
	declare @IdPizza int
	declare @IdIngrediente int

	select @IdPizza = p.CodicePizza from Pizza p where p.NomePizza=@nomePizza
	select @IdIngrediente = i.CodiceIngrediente from Ingrediente i where i.NomeIngrediente=@nomeIngrediente

	insert into IngredientePizza values (@IdIngrediente, @IdPizza)

	end try
	begin catch
	select Error_message(), Error_line()
	end catch
End

execute AssegnaIngredienteAPizza 'cotto','Cotto e funghi'

--3. Aggiornamento del prezzo di una pizza (parametri: nome e nuovo prezzo)

create procedure AggiornaPrezzoPizza
@nomePizza nvarchar(40),
@prezzo decimal(4,2)
AS
Begin
	begin try

	update Pizza Set Prezzo = @prezzo where NomePizza=@nomePizza

	end try
	begin catch
	select error_message(), error_line()
	end catch
End

execute AggiornaPrezzoPizza 'Cotto e funghi',7.00

--4. Eliminazione di un ingrediente da una pizza (parametri: nome pizza, nome ingrediente) 

create procedure EliminaIngredientePizza
@nomeIngrediente nvarchar(40),
@nomePizza nvarchar(40)
AS
Begin
	begin try

	declare @IdPizza int
	declare @IdIngrediente int

	select @IdPizza = p.CodicePizza from Pizza p where p.NomePizza=@nomePizza
	select @IdIngrediente = i.CodiceIngrediente from Ingrediente i where i.NomeIngrediente=@nomeIngrediente

	delete from IngredientePizza where CodiceIngrediente=@IdIngrediente AND CodicePizza=@IdPizza

	end try
	begin catch
	select Error_Message(), Error_line()
	end catch
End

execute EliminaIngredientePizza 'mozzarella','Cotto e funghi'

--5. Incremento del 10% del prezzo delle pizze contenenti un ingrediente (parametro: nome ingrediente)

create procedure IncrementaPrezzoPerIngrediente
@nomeIngrediente nvarchar(40)
AS
Begin
	begin try
	declare @incremento decimal(2,1) = 0.1

	update Pizza Set Prezzo = (Prezzo* (1 + @incremento)) 
			where NomePizza IN (select p.NomePizza			
								from Pizza p join IngredientePizza ipi on p.CodicePizza=ipi.CodicePizza
											 join Ingrediente i on ipi.CodiceIngrediente=i.CodiceIngrediente
								where i.NomeIngrediente= @nomeIngrediente)

	end try
	begin catch
	select ERROR_MESSAGE(),ERROR_LINE()
	end catch
End

execute IncrementaPrezzoPerIngrediente 'grana'

/** FUNZIONI**/
--1. Tabella listino pizze (nome, prezzo) ordinato alfabeticamente (parametri:nessuno)create function ListinoPizze()returns tableASReturnselect top 10000 p.NomePizza as [Nome], p.Prezzo as [Prezzo]From Pizza pOrder by p.NomePizza --non posso farlo dentro la funzione, lo farò nel select esterno					--oppure posso metterlo qui se uso il top10000select *from dbo.ListinoPizze()--2. Tabella listino pizze (nome, prezzo) contenenti un ingrediente (parametri: nome ingrediente)create function ListinoPizzeConIngrediente(@nomeIngrediente nvarchar(40))returns tableASReturnselect p.NomePizza as [Nome], p.Prezzo as [Prezzo]From  Pizza p join IngredientePizza ipi on p.CodicePizza=ipi.CodicePizza
			 join Ingrediente i on ipi.CodiceIngrediente=i.CodiceIngrediente
where i.NomeIngrediente= @nomeIngredienteselect *from dbo.ListinoPizzeConIngrediente('rucola')order by Nome--3. Tabella listino pizze (nome, prezzo) che non contengono un certo ingrediente (parametri: nome ingrediente)create function ListinoPizzeSenzaIngrediente (@nomeIngrediente nvarchar(40))returns tableASReturnselect p.NomePizza as [Nome], p.Prezzo as [Prezzo]
from Pizza p 
where p.NomePizza not in (select p.NomePizza
						  from Pizza p join IngredientePizza Ipi on p.CodicePizza=Ipi.CodicePizza
									   join Ingrediente i on Ipi.CodiceIngrediente=i.CodiceIngrediente
						  where i.NomeIngrediente=@nomeIngrediente)select *from ListinoPizzeSenzaIngrediente('pomodoro')order by Nome--4. Calcolo numero pizze contenenti un ingrediente (parametri: nome ingrediente)create function NumeroPizzeConIngrediente (@nomeIngrediente nvarchar(40))returns intASbegin declare @numeroPizze intselect @numeroPizze=count(*) From  Pizza p join IngredientePizza ipi on p.CodicePizza=ipi.CodicePizza
			 join Ingrediente i on ipi.CodiceIngrediente=i.CodiceIngrediente
where i.NomeIngrediente= @nomeIngrediente

return @numeroPizze
end

select dbo.NumeroPizzeConIngrediente('pomodoro') as [# pizze]

--5. Calcolo numero pizze che non contengono un ingrediente (parametri: codice ingrediente)

create function NumeroPizzeSenzaIngrediente (@nomeIngrediente nvarchar(40))returns intASbegin declare @numeroPizze intselect @numeroPizze=count(*)
from Pizza p 
where p.NomePizza not in (select p.NomePizza
						  from Pizza p join IngredientePizza Ipi on p.CodicePizza=Ipi.CodicePizza
									   join Ingrediente i on Ipi.CodiceIngrediente=i.CodiceIngrediente
						  where i.NomeIngrediente=@nomeIngrediente)return @numeroPizzeendselect dbo.NumeroPizzeSenzaIngrediente('funghi') as [# pizze]--6. Calcolo numero ingredienti contenuti in una pizza (parametri: nome pizza)create function NumeroIngredientiPerPizza(@nomePizza nvarchar(40))returns intASbegin declare @numeroIngredienti intselect @numeroIngredienti=count(i.CodiceIngrediente)from Pizza p join IngredientePizza Ipi on p.CodicePizza=Ipi.CodicePizza
		     join Ingrediente i on Ipi.CodiceIngrediente=i.CodiceIngrediente
where p.NomePizza=@nomePizzareturn @numeroIngredientiendselect dbo.NumeroIngredientiPerPizza('quattro stagioni') as [# ingredienti]/** VIEW**/--Realizzare una view che rappresenta il menù con tutte le pizze.Create view Menu ([Nome Pizza], [Prezzo], [Ingredienti])
as(
select top 1000 p.NomePizza as [Nome Pizza], p.Prezzo as [Prezzo], i.NomeIngrediente as [Ingredienti]
from Pizza p join IngredientePizza Ipi on p.CodicePizza=Ipi.CodicePizza
			 join Ingrediente i on Ipi.CodiceIngrediente=i.CodiceIngrediente
order by [Nome Pizza]
)select * from Menu-- VISTA OPZIONALEcreate function AggregaIngredientiPerPizza(@nomePizza nvarchar(40))returns nvarchar(max)AS begindeclare @listaIngredienti nvarchar(max)select @listaIngredienti = Coalesce(@listaIngredienti + ',' + i.NomeIngrediente, i.NomeIngrediente)from Pizza p join IngredientePizza Ipi on p.CodicePizza=Ipi.CodicePizza
			 join Ingrediente i on Ipi.CodiceIngrediente=i.CodiceIngrediente
where p.NomePizza =@nomePizza

return @listaIngredienti
end

--select dbo.AggregaIngredientiPerPizza('Diavola')

create view MenuListaIngredienti ([Nome Pizza], [Prezzo], [Ingredienti])
as(
select distinct top 1000 p.NomePizza, p.Prezzo as [Prezzo], dbo.AggregaIngredientiPerPizza(p.NomePizza) from Pizza p join IngredientePizza Ipi on p.CodicePizza=Ipi.CodicePizza
			 join Ingrediente i on Ipi.CodiceIngrediente=i.CodiceIngrediente
)


select*
from MenuListaIngredienti
