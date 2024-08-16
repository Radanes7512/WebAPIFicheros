 --Querys e incidencias diarias 
-- Son incidencias recurrentes, que normalmente se encuentran en  la base de datos EProviderInvoice
-- Revisar siempre los campos para saber que dato meter

--SystemReply - Proveedores sin acceso %3D ("PROD Cuidado!! - Proveedores Sin Acceso")
--Nuscamos el error
SELECT * FROM CXB_EPI_Provider where PI_PROVIDER_IdProvider = 00
--Tabla a corregir
select * from CXB_EPI_ProviderUser where PI_PROVUSER_IdProvUser in (24795,24796)
--cambiar el '%3d' del final del Code por un '='
update CXB_EPI_ProviderUser set PI_PROVUSER_Code = '' where PI_PROVUSER_IdProvUser= 24795


--Poner A nueva 
-----------------------------------------------
--El proceso se ha automatizao pero suelen poner alguna, estas que ponen son urgentes ya que su estado es Pendiente de Custodia o Pendiente de Enviar
--Buscamos la factura previamente escrita en el ticket mediante la referencia, y obtenemos su IDEinvoice
--Revisar horas si se hace el cambio 
----------------------------------------------------------------------------------------------------------
--Ambas se ejecutan cada HORA
--Horas en las que se ejecuta la tarea de Custodia   5:00 / 6:00 / 7:00 /...../ 13:00 / 15:00 / 17:00 (Tarea - Enviar facturas Proveedores Caixabank a Custodia LGT)
--Horas en las que se ejecuta la tarea de Enviar CXF 8:40 / 9:40 /10:40 /...../ 13:40 /15:40 / 20:40  (Tarea - Enviar Facturas Proveedores SFTP CXB)
----------------------------------------------------------------------------------------------------------

--Parte 1
--Segun la hora del ticket y el cambio revisar la tarea por si se es ejeutando para no realizar el cambio hasta que la tarea acabe
SELECT * FROM CXB_EPI_EInvoice WHERE PI_INV_DeliveryReference in ( 'EFAC_XXXXX_XXXXX')
--Con IDEinvoice localizado hacemos el UPDATE antes de que pase la tarea 
UPDATE CXB_EPI_EInvoice SET PI_INV_EstadoFacturaCaption = 'Alta previa', PI_INV_EstadoFacturaInterno = 'AltaPrevia' WHERE PI_INV_IdEInvoice = 84357
UPDATE CXB_EPI_EInvoice SET PI_INV_EstadoFacturaCaption = 'Nueva', PI_INV_EstadoFacturaInterno = 'Nueva' WHERE PI_INV_IdEInvoice = 84357
UPDATE CXB_EPI_EInvoice SET PI_INV_EstadoFacturaCaption = 'Pendiente de validar', PI_INV_EstadoFacturaInterno = 'PdteValidar' WHERE PI_INV_IdEInvoice = 84357
UPDATE CXB_EPI_EInvoice SET PI_INV_EstadoFacturaCaption = 'Pendiente de rechazar', PI_INV_EstadoFacturaInterno = 'PdteRechazar', PI_INV_Deleted = null, 
UPDATE CXB_EPI_EInvoice SET PI_INV_EstadoFacturaCaption = 'Pendiente enviar custodia', PI_INV_EstadoFacturaInterno = 'PdteEnvCustodia' WHERE PI_INV_IdEInvoice = 84357
UPDATE CXB_EPI_EInvoice SET PI_INV_EstadoFacturaCaption = 'Pendiente Caixafactura', PI_INV_EstadoFacturaInterno = 'PdteCXF' WHERE PI_INV_IdEInvoice = 76246
UPDATE CXB_EPI_EInvoice SET PI_INV_EstadoFacturaCaption = 'Enviada Caixafactura', PI_INV_EstadoFacturaInterno = 'EnvCXF' WHERE PI_INV_IdEInvoice = 76246
UPDATE CXB_EPI_EInvoice SET PI_INV_EstadoFacturaCaption = 'Dividir', PI_INV_EstadoFacturaInterno = 'Dividir' WHERE PI_INV_IdEInvoice = 84357
UPDATE CXB_EPI_EInvoice SET PI_INV_EstadoFacturaCaption = 'Carta Procesada', PI_INV_EstadoFacturaInterno = 'CartaProcesada' WHERE PI_INV_IdEInvoice = 84357
UPDATE CXB_EPI_EInvoice SET PI_INV_EstadoFacturaCaption = 'Rechazada', PI_INV_EstadoFacturaInterno = 'Rechazada' WHERE PI_INV_IdEInvoice = 956614
UPDATE CXB_EPI_EInvoice SET PI_INV_EstadoFacturaCaption = 'Aplazada', PI_INV_EstadoFacturaInterno = 'Aplazada' WHERE PI_INV_IdEInvoice = 84357

--Despues de ponerla a nueva ,lo reflejamos en el historial para que quede constancia del cambio
INSERT INTO CXB_EPI_StatusHistory (PI_SH_IdEInvoice, PI_SH_InvoiceStatus, PI_SH_Date, PI_SH_InvoiceStatusCaption, PI_SH_Visible, PI_SH_Comments, PI_SH_CreationUser, PI_SH_CreationDate)
VALUES (IdFac, 'Nueva', GETDATE(), 'Nueva', 1, 'Error nuestro NºTicket', IDusuario, GETDATE())
--Con la Factura a Nueva, sacamos los datos para encolarla de nuevo
SELECT PI_INV_InvoiceNumber,PI_INV_InvoiceDate,PI_INV_IdEInvoice,PI_INV_Priority, PI_INV_InvoiceBankia, PI_INV_CreationDate FROM CXB_EPI_EInvoice 
WHERE PI_INV_DeliveryReference  in ( 'EFAC_XXXXX_XXXXX')
--Por ultimo metemos en la COLA la factura y sus datos y revisamos que entro correctamente
INSERT INTO CXB_EPI_EInvoiceFifoQueue (PI_INVFIFO_EInvNumber, PI_INVFIFO_EInvDate, PI_INVFIFO_IdInvoice, PI_INVFIFO_Priority,PI_INVFIFO_InvoiceBankia,PI_INVFIFO_CreateDateInvoice) 
VALUES ('INVNumber','fecha',idEinvocies,2,0,'Fecha')
--Colas 
SELECT * FROM CXB_EPI_EInvoiceFifoQueue				--Pendiente de procesar
SELECT * FROM CXB_EPI_PendingToRegisterFifoQueue	--Pendiente de Validar
SELECT * FROM CXB_EPI_RefusedEInvoiceFifoQueue		--Rechazadas
SELECT * FROM CXB_EPI_ReturnedEInvoiceFifoQueue		--Devueltas(No suelen haber devueltas)

--Parte 2
--Si la factura a nueva no a pasado por el estado Enviado Caixafactura omitir este paso
--Si a pasdo y se ha enviado almenos una vez y es ERROR NUESTRO realizar lo siguiente en la BBDD NotificationInvoices
--Buscamos la factura que hemos puesta a NUEVA y vemos cuantas lineas de facturacion tiene
SELECT * FROM UFCXB_InvoiceTemporalMain WHERE UFCXB_INVMAIN_IdEInvoice IN (00) ORDER BY UFCXB_INVMAIN_IdEInvoice, UFCXB_INVMAIN_CreationDate
--Si tiene dos o lineas de facturacion "EIMINAR" la mas vieja y dejar la reciente, pero si la vieja esta ya facturada borrar la nueva ya que se a facturado
--Para saber si se a facturado , revisar los campos delete, delete date y delete user o preguntar a NOELIA O MARGUIE para más seguridad en caso de duda
UPDATE UFCXB_InvoiceTemporalMain  SET UFCXB_INVMAIN_Deleted = 1, UFCXB_INVMAIN_DeleteDate=GETDATE(), UFCXB_INVMAIN_DeleteUser= IDUsuario, UFCXB_INVMAIN_Comments = 'ERROR NUESTRO NºTicket' WHERE UFCXB_INVMAIN_IdUFCxbInvoiceMain = 00

--Parte 3 Encolar facturas de ASSET si Raquel pide encolar FACTURAS DE ASSET, necesitamos 
--Los EFAC
--Dia por el que van facturando
--con los EFAC sacamos el IDEinvoices, si por algun casual no lo encunetras a la primera usa el Like para buscarlos, aveces se resisten
select * from CXB_EPI_EInvoice where PI_INV_DeliveryReference in ('EFAC_XXXXX_XXXXX')
--Con los IDEinvoice ya localizados revisamos el estado y si estan a nueva significa que ya se han encolado pero del dia de hoy y ellas necesitas que le salga de las primeras
--Con los IDEinvoice  vamos a fifo las buscamos 
select * from CXB_EPI_EInvoiceFifoQueue where PI_INVFIFO_IdInvoice in (idEinvocies)
--Modificamos el campo PI_INVFIFO_CreateDateInvoice para que les salga de las primera a la hora de procesar 
UPDATE CXB_EPI_EInvoiceFifoQueue set PI_INVFIFO_CreateDateInvoice = '2021-08-01 12:20:03.697' where PI_INVFIFO_IdInvoice in  (idEinvocies)

--Facturacion Mensaul
-----------------------------------------------
--La facturacion mensual es una serie de facturas que nos ponen para eliminarlas o modificarla, hay 4 tipos de facturas
-- * BPO  - UFGDS_InvoiceTemporalMain
-- * FastFac - UFCXB_InvoiceTemporalMain
-- * Upload - UFCXB_InvoiceTemporalMain
-- * Upload Bankia - UFCXB_InvoiceTemporalMain

--FASTFAC y UPLOAD
SELECT * FROM UFCXB_InvoiceTemporalMain WHERE UFCXB_INVMAIN_ProvimadReference IN (00) ORDER BY UFCXB_INVMAIN_IdEInvoice
--"Eliminar Linea"
UPDATE UFCXB_InvoiceTemporalMain SET UFCXB_INVMAIN_Deleted = 1, UFCXB_INVMAIN_DeleteDate = GETDATE(), UFCXB_INVMAIN_DeleteUser = 53, UFCXB_INVMAIN_Comments = concat(UFCXB_INVMAIN_Comments, '- Facturación Noelia Fecha')
WHERE UFCXB_INVMAIN_IdUFCxbInvoiceMain IN (00)


--BPO
SELECT * FROM UFGDS_InvoiceTemporalMain WHERE UFGDS_INVMAIN_ProvimadReference IN (00)
--"Eliminar Linea"
UPDATE UFGDS_InvoiceTemporalMain SET  UFGDS_INVMAIN_Deleted = 1, UFGDS_INVMAIN_DeleteDate = GETDATE(), UFGDS_INVMAIN_DeleteUser= 53, UFGDS_INVMAIN_Comments = concact(UFGDS_INVMAIN_Comments,'- Facturación Noelia Fecha') 
WHERE UFGDS_INVMAIN_IdUFGdsInvoiceMain in (00)


--Modificar las facturas
--UPDATE  la suma de las linea tiene que dar
--FF = 3€, UPLOAD/UPLOAD BANKIA = 2€, BPO= 4€
--Los cabios los proporcionan en el ticket
-- Si descuadra para ver cuales son las que faltan usamos el siguiente comando en excel,C de la tabla que nos pasan a la que descuadra =BUSCARV(C16421;[Libro2]Hoja2!$A:$A;1;FALSO)
--SELECT UPLOAD
select UFCXB_INVMAIN_IdUFCxbInvoiceMain,UFCXB_INVMAIN_IdEInvoice,UFCXB_INVMAIN_ProvimadReference, UFCXB_INVMAIN_CSoporte, UFCXB_INVMAIN_CEntryData, UFCXB_INVMAIN_CValidacion, 
UFCXB_INVMAIN_CCertificacion, UFCXB_INVMAIN_Custodia_1_750, UFCXB_INVMAIN_ImporteBase, UFCXB_INVMAIN_Comments, UFCXB_INVMAIN_DeleteUser, UFCXB_INVMAIN_DeleteDate, UFCXB_INVMAIN_Deleted, 
UFCXB_INVMAIN_CreationDate from UFCXB_InvoiceTemporalMain where UFCXB_INVMAIN_ProvimadReference in 
()
--UPLOAD / UPLOAD BANKIA
UPDATE UFCXB_InvoiceTemporalMain
SET UFCXB_INVMAIN_CSoporte = 0.26, 
UFCXB_INVMAIN_CEntryData = 0.8, 
UFCXB_INVMAIN_CValidacion = 0.2, 
UFCXB_INVMAIN_CCertificacion = 0.12, 
UFCXB_INVMAIN_Custodia_1_750 = 0.12, 
UFCXB_INVMAIN_CGeneracionFacturae = 0.2, 
UFCXB_INVMAIN_ImporteBase = 1.7, 
UFCXB_INVMAIN_Comments = concat(UFCXB_INVMAIN_Comments, ' - Facturación Noelia Fecha'), 
UFCXB_INVMAIN_UPDATEDate = GETDATE(), UFCXB_INVMAIN_UPDATEUser = 53
WHERE UFCXB_INVMAIN_IdUFCxbInvoiceMain in()


--SELECT FF
select UFCXB_INVMAIN_IdUFCxbInvoiceMain,UFCXB_INVMAIN_IdEInvoice,UFCXB_INVMAIN_ProvimadReference, UFCXB_INVMAIN_CSoporte, UFCXB_INVMAIN_CEntryData, UFCXB_INVMAIN_CValidacion, 
UFCXB_INVMAIN_CCertificacion, UFCXB_INVMAIN_Custodia_1_750, UFCXB_INVMAIN_ImporteBase, UFCXB_INVMAIN_Comments, UFCXB_INVMAIN_DeleteUser, UFCXB_INVMAIN_DeleteDate, UFCXB_INVMAIN_Deleted, 
UFCXB_INVMAIN_CreationDate from UFCXB_InvoiceTemporalMain where UFCXB_INVMAIN_ProvimadReference in 
()
--FAST.FAC
UPDATE UFCXB_InvoiceTemporalMain
SET UFCXB_INVMAIN_CSoporte = 1.8, 
UFCXB_INVMAIN_CEntryData = 0.8, 
UFCXB_INVMAIN_CValidacion= 0.2, 
UFCXB_INVMAIN_CCertificacion = 0, 
UFCXB_INVMAIN_Custodia_1_750 = 0, 
UFCXB_INVMAIN_CGeneracionFacturae = 0.2, 
UFCXB_INVMAIN_ImporteBase = 3,  
UFCXB_INVMAIN_Comments = concat(UFCXB_INVMAIN_Comments, ' - Facturación Noelia Fecha'), 
UFCXB_INVMAIN_UPDATEDate = GETDATE(), UFCXB_INVMAIN_UPDATEUser = 53
WHERE UFCXB_INVMAIN_IdUFCxbInvoiceMain in()

--SELECT BPO
select UFGDS_INVMAIN_IdUFGdsInvoiceMain,UFGDS_INVMAIN_IdEInvoice,UFGDS_INVMAIN_ProvimadReference,UFGDS_INVMAIN_CSoporte,UFGDS_INVMAIN_CEntryData,
UFGDS_INVMAIN_CValidacion,UFGDS_INVMAIN_CCertificacion,UFGDS_INVMAIN_Custodia_1_750,UFGDS_INVMAIN_ImporteBase,
UFGDS_INVMAIN_Deleted,UFGDS_INVMAIN_DeleteDate,UFGDS_INVMAIN_DeleteUser from UFGDS_InvoiceTemporalMain where UFGDS_INVMAIN_ProvimadReference in 
()
--BPO
UPDATE UFGDS_InvoiceTemporalMain
SET UFGDS_INVMAIN_CSoporte = 2.46, 
UFGDS_INVMAIN_CEntryData = 0.8, 
UFGDS_INVMAIN_CValidacion = 0.2, 
UFGDS_INVMAIN_CCertificacion = 0.12, 
UFGDS_INVMAIN_Custodia_1_750 = 0.12, 
UFGDS_INVMAIN_CGeneracionFacturae = 0.2, 
UFGDS_INVMAIN_ImporteBase = 3.90, 
UFGDS_INVMAIN_Comments = concat(UFGDS_INVMAIN_Comments, ' - Facturación Noelia Fecha'), 
UFGDS_INVMAIN_UPDATEDate = GETDATE(), UFGDS_INVMAIN_UPDATEUser = 53
WHERE UFGDS_INVMAIN_IdUFGDSInvoiceMain in()

--Por ultimo vamos al servidor de CESSPRo y en la parte de facturacion generamos las facturas y comprabamos que coinciden 
--los datos con lo del Excel proporcionado por el ticket


----Cambiar el CIF de un cliente provedor
-----------------------------------------------
----Sacamos los datos , el identNumber te lo proporcionan en el ticket
SELECT * FROM CXB_EPI_Provider WHERE PI_PROVIDER_IdentNumber = 'J00000001'
--Hacemos el UPDATE sobre el campo que deseamos cambiar
UPDATE CXB_EPI_Provider  SET PI_PROVIDER_IdentNumber = 'J00000000' WHERE PI_PROVIDER_IdProvider = 00
--Comprobamos que el cambio se ha realizado, tambien deberiamos mirar en CessPro que el cambio este hecho


--Errores Envio de FActuras Caracter Hexadecimal(Correos de SystemReply con priorodad)
-----------------------------------------------
--Usa un bloc de notas para ver el error de 0x06 Hexadecimal, se ve mas claro
--La base es EProviderInvoice
--SELECT para sacar lines donde pueda estar el error
SELECT * FROM CXB_EPI_SuppliedConcepts WHERE PI_CSUP_Concept LIKE '%' + CHAR(0x06) +'%'
SELECT * FROM CXB_EPI_OutputsConcepts WHERE PI_COUTP_Concept LIKE '%' + CHAR(0x06) +'%'
SELECT * FROM CXB_EPI_WithheldConcepts WHERE PI_CWITH_Concept LIKE '%' + CHAR(0x06) +'%'
SELECT * FROM CXB_EPI_OutWithConcepts WHERE PI_COUWH_Concept LIKE '%' + CHAR(0x06) +'%'
---- Hacemos el UPDATE correspondiente, teniendo en cuenta el PI_COUTP_IdEInvoice o el PI_COUTP_IdOutputsConcepts
--------PI_COUTP_IdEInvoice
UPDATE CXB_EPI_OutputsConcepts SET PI_COUTP_Concept ='XXX' WHERE PI_COUTP_IdEInvoice = 278510
--------PI_COUTP_IdOutputsConcepts
UPDATE CXB_EPI_OutputsConcepts SET PI_COUTP_Concept ='HTV 43" PROF. SAMSUNG LYNKCLOUD NETFLIX'WHERE PI_COUTP_IdOutputsConcepts = 773152
------------Si ejecuta la cuery pero el error sigue utiliza [REPLACE(PI_COUTP_Concept, CHAR(0x06), '')]
UPDATE CXB_EPI_OutputsConcepts SET PI_COUTP_Concept = REPLACE(PI_COUTP_Concept, CHAR(0x06), '') WHERE PI_COUTP_IdOutputsConcepts = 773152
UPDATE CXB_EPI_OutputsConcepts SET PI_COUTP_Concept = REPLACE(PI_COUTP_Concept, CHAR(0x06), '') WHERE PI_COUTP_Concept LIKE '%' + CHAR(0x06) +'%'


----- Cambiar nombre a las empresas Web Ipload
-----------------------------------------------
--Buscamos la factura
SELECT * FROM PCI_EProviderInvoiceInvoiceReceivers WHERE PCI_IR_TaxIdentNumber = 'G66798224'
--Hacemos el UPDATE de la linea
UPDATE PCI_EProviderInvoiceInvoiceReceivers SET PCI_IR_CompanyName = 'ASOCIACIÓN DE VOLUNTARIOS DE CAIXABANK', PCI_IR_LegalEntityCorporateName = 'ASOCIACIÓN DE VOLUNTARIOS DE CAIXABANK' WHERE PCI_IR_IdInvoiceReceiver = 25


-- Query para sacar los Burofaxes CXB (caixa) de Cesspro con sus detalles, del todo el año 2021
select T.CB_NOTIFICATION_RequestDate, T.CB_NOTIFICATION_NotificationRef, T.CB_NR_Acknowledgment, CB_NR_CertifiedCopy, CB_NR_ExtraPages, CB_NOTIFICATION_NumberReceivers, CB_NOTIFICATION_DTCenter, CB_NOTIFICATION_OfficeCenter, 
CB_USER_Enrollment, CB_NOTIFICATION_SendMode, CB_RECEIVER_DeliveryReference, CB_NR_ProvimadStatus, CB_NR_OperatorStatus, CB_NR_ProviderReference, CB_NR_DocAck, CB_NR_DocCopy, CB_NR_DetectedError, CB_RECEIVER_Name, CB_RECEIVER_FirstName, CB_RECEIVER_LastName, CB_RECEIVER_Company, CB_NR_FileCreationDate, CB_NR_IsSP ,CONCAT( CB_INV_InvoiceSerie, '/' ,CB_NR_InvoiceNumber) from (
	select * from CB_NOTIFIC_Receivers as reciv
	inner join(
			select * from CB_NOTIFIC_User as users
			inner join (
			  select * from CB_NOTIFIC_Invoice as Invoic
				inner join
				(
					select * from CB_NOTIFIC_NotificationsReceivers as NotfRec
					right join(
						select [CB_NOTIFICATION_IdNotification]
							  ,[CB_NOTIFICATION_NotificationRef],[CB_NOTIFICATION_NotificationType],[CB_NOTIFICATION_Cause],[CB_NOTIFICATION_RequestDate]
							  ,[CB_NOTIFICATION_InsertRequestDate],[CB_NOTIFICATION_FilePath],[CB_NOTIFICATION_IsGIM],[CB_NOTIFICATION_ContractType]
							  ,[CB_NOTIFICATION_Product],[CB_NOTIFICATION_AnnexProduct],[CB_NOTIFICATION_ContractNumber],[CB_NOTIFICATION_SpendigType]
							  ,[CB_NOTIFICATION_DTCenter],[CB_NOTIFICATION_OfficeCenter]
							  ,[CB_NOTIFICATION_SendMode],[CB_NOTIFICATION_SendType],[CB_NOTIFICATION_CFUser],[CB_NOTIFICATION_IdUser],[CB_NOTIFICATION_IdService]
							  ,[CB_NOTIFICATION_TermLegalAction],[CB_NOTIFICATION_NumberReceivers]
							  ,[CB_NOTIFICATION_DeliveryType],[CB_NOTIFICATION_Comments],[CB_NOTIFICATION_CreationUser],[CB_NOTIFICATION_CreationDate]
							  ,[CB_NOTIFICATION_UpdateUser],[CB_NOTIFICATION_UpdateDate],[CB_NOTIFICATION_DeleteUser],[CB_NOTIFICATION_DeleteDate],[CB_NOTIFICATION_Deleted]
							  ,[CB_NOTIFICATION_Remitente2] from CB_NOTIFIC_Notifications where CB_NOTIFICATION_RequestDate > '2021-01-01 00:00:00.000' AND CB_NOTIFICATION_RequestDate < '2022-01-01 00:00:00.000'
						) as Notf
					On Notf.CB_NOTIFICATION_IdNotification = NotfRec.CB_NR_IdNotification
				) as NotfDetalle
				on Invoic.CB_INV_IdInvoice = NotfDetalle.CB_NR_InvoiceNumber
			) as inUser
			on users.CB_USER_IdUser = inUser.CB_NOTIFICATION_IdUser
		) as inReciv
		on reciv.CB_RECEIVER_IdReceiver = inReciv.CB_NR_IdReceiver
) as T 










