# -*- coding: utf-8 -*-
from odoo.tools.misc import DEFAULT_SERVER_DATETIME_FORMAT
import unicodedata
from openerp.exceptions import Warning
import time
from odoo.exceptions import UserError
import odoo.addons.decimal_precision as dp
from openerp.osv import osv
import base64
from odoo import models, fields, api
from tempfile import TemporaryFile
import codecs
from xlrd import *
import xlrd
from datetime import datetime, timedelta
import re
import decimal


class convertidor_protestos(models.TransientModel):
	_name = 'convertidor.protestos'
	excel_file= fields.Binary('Adjuntar Excel a Convertir',required=True)
	numero_boletin= fields.Char('Numero de Boletin', size=6)
	state = fields.Selection( [('protestos','PROTESTOS'),('moran','MORAS')],'Tipo',default='protestos')


	@api.multi
	def do_oexcel(self):
		print('asdas')
		print('rico pe')
		file_data = self.excel_file.decode('base64')
		data_row = []
		pepe = ''
		match = ''
		vacio = ' '
		vacio = vacio.ljust(60,' ')
		wb = open_workbook(file_contents=file_data)
		for s in wb.sheets():
			if s.name == 'DATA':
				nota = (s.cell(1,2).value)
				self.env.cr.execute("""
				select codigo,name from notarias_modelo where name = '"""+str(nota)+"""'
				"""
					)
				notarias = list(self.env.cr.dictfetchall())
				if len(notarias)>0:
					for notaria in notarias:
						print(notaria['name'])
						print(notaria['codigo'])
						codigo = notaria['codigo']
				else:
					raise UserError("La Notaria "+str(nota)+", seleccionada en el Documento(Excel) no se encuentra resitrada en el sistema; para continuar primero debe registrarla en Configuracion/Notarias.")
				for row in range(s.nrows):
					data_row = []
					notaria = (s.cell(1,2).value)
					
					if row > 3:
						valor = (s.cell(row,29).value)
						valor2 = (s.cell(row,6).value)
						valor2n=valor2.ljust(60,' ')
						if (s.cell(row,7).value) == 'RUC':
							valor3 = '4'
							valor4 = str(s.cell(row,8).value)
							valor4 = valor4.split('.', 1)
				
							match = re.match(r'\b[0-9]{11}\b',valor4[0],re.I)
							if not match:
								raise UserError("El Documento RUC Del Aceptante debe tener 11 digitos y debe ser un valor Entero("+valor2+")")
						elif (s.cell(row,7).value) == 'DNI':
							valor3 = '1'
							valor4 = str(s.cell(row,8).value)
							valor4= valor4.split('.', 1)
					
							match = re.match(r'\b[0-9]{8}\b',valor4[0],re.I)
							if not match:
								raise UserError("El Documento DNI del Aceptante debe tener 8 digitos y debe ser un valor Entero("+valor2+")")

						valor4n = valor4[0].rjust(11,'0')
						valor5 = (s.cell(row,9).value)
						valor5n=valor5.ljust(60,' ')
						valor6 = (s.cell(row,10).value)
						valor7 = float(s.cell(row,11).value)
						valor7 = '{:,.2f}'.format(decimal.Decimal("%0.2f"%valor7))
						valor7 = valor7.split('.', 1)
						valor7n = valor7[0] + valor7[1]
						valor7n = valor7n.split(',', 1)

						if len(valor7n)>1:
							valor7n1 =  valor7n[0] + valor7n[1]
						else:
							valor7n1 =  valor7n[0]

						valor7n1 = valor7n1.rjust(16,'0')
						valor8 = codigo
						valor8 = valor8.rjust(7,'0')
						valor8 = valor8.ljust(10,' ')
						valor9 = '0'
						if self.numero_boletin:
							valor9 = self.numero_boletin
						valor9 = valor9.rjust(6,'0')
						valor9 = valor9.ljust(15,' ')

						valor10 = '0000'

						valor11 = (s.cell(row,2).value)
						valor11n = valor11.ljust(60,' ')
						valor12 = ' '
						if (s.cell(row,3).value) == 'RUC':
							valor12 = '4'
							valor13 = str(s.cell(row,4).value)
							valor13= valor13.split('.', 1)
						
							match = re.match(r'\b[0-9]{11}\b',valor13[0],re.I)
							if not match:
								raise UserError("El Documento RUC Del Girador debe tener 11 digitos y debe ser un valor Entero("+valor11+")")
						elif (s.cell(row,3).value) == 'DNI':
							valor12 = '1'
							valor13 = str(s.cell(row,4).value)
							valor13= valor13.split('.', 1)
							
							match = re.match(r'\b[0-9]{8}\b',valor13[0],re.I)
							if not match:
								raise UserError("El Documento DNI del Girador debe tener 8 digitos y debe ser un valor Entero("+valor11+")")
						valor13n = valor13[0].rjust(11,'0')
						valor13n = valor13[0].ljust(27,' ')
						valor14 = s.cell_value(row,0)
						
						valor14 = xlrd.xldate_as_tuple(valor14, wb.datemode)  
						valor14n = datetime(*valor14)
						valor14n = valor14n.strftime("%Y%m%d")

						valor15='19660-6'
						valor15 = valor15.ljust(16,' ') 
						#fecha_hoy = str(datetime.datetime.now())[:10]
						now = fields.Date.from_string(fields.Date.context_today(self))
						valor16 = now.strftime("%Y%m%d")
						valor17 = str(s.cell(row,12).value)
						valor17 = valor17[:3]
						valor18 = ' '
						print(valor17)
						if self.state == 'protestos':
							valor18 = 'PR1A'
						else:
							valor18 = 'MO1A'

						#AVAL1
						valor19 = (s.cell(row,13).value)
						valor19 = valor19.ljust(60,' ')
						valor20 = ' '
						valor21 = ' '
						if (s.cell(row,14).value) == 'RUC':
							valor20 = '4'
							valor21 = str(s.cell(row,15).value)
							valor21= valor21.split('.', 1)
						
							match = re.match(r'\b[0-9]{11}\b',valor21[0],re.I)
							if not match:
								raise UserError("El Documento RUC Del Primer Aval debe tener 11 digitos y debe ser un valor Entero("+valor19+")")
						elif (s.cell(row,14).value) == 'DNI':
							valor20 = '1'
							valor21 = str(s.cell(row,15).value)
							valor21= valor21.split('.', 1)

							match = re.match(r'\b[0-9]{8}\b',valor21[0],re.I)
							if not match:
								raise UserError("El Documento DNI del Primer Aval debe tener 8 digitos y debe ser un valor Entero("+valor19+")")
						valor21n = ' '
						valor21n = valor21[0].rjust(11,' ')
						if valor21n != '           ':
							valor21n = valor21[0].rjust(11,'0')
						direccion_aval_1 = ' '
						direccion_aval_1 = s.cell(row,16).value
						print(s.cell(row,16).value)

						if valor19 != vacio:
							tipo_aval_1 = 'A'
						else:
							tipo_aval_1 = ' '
						direccion_aval_1 = direccion_aval_1.ljust(60,' ')



						#AVAL2
						valor22 = (s.cell(row,17).value)
						valor22 = valor22.ljust(60,' ')
						valor23 = ' '
						valor24 = ' '
						if (s.cell(row,18).value) == 'RUC':
							valor23 = '4'
							valor24 = str(s.cell(row,19).value)
							valor24= valor24.split('.', 1)
						
							match = re.match(r'\b[0-9]{11}\b',valor24[0],re.I)
							if not match:
								raise UserError("El Documento RUC Del Segundo Aval debe tener 11 digitos y debe ser un valor Entero("+valor22+")")
						elif (s.cell(row,18).value) == 'DNI':
							valor23 = '1'
							valor24 = str(s.cell(row,19).value)
							valor24= valor24.split('.', 1)

							match = re.match(r'\b[0-9]{8}\b',valor24[0],re.I)
							if not match:
								raise UserError("El Documento DNI del Segundo Aval debe tener 8 digitos y debe ser un valor Entero("+valor22+")")
						valor24n = ' '
						valor24n = valor24[0].rjust(11,' ')
						if valor24n != '           ':
							valor24n = valor24[0].rjust(11,'0')
						direccion_aval_2 = ' '
						direccion_aval_2 = s.cell(row,20).value
						if valor22 != vacio:
							tipo_aval_2 = 'A'
						else:
							tipo_aval_2 = ' '
						direccion_aval_2 = direccion_aval_2.ljust(60,' ')

						#AVAL3
						valor25 = (s.cell(row,21).value)
						valor25 = valor25.ljust(60,' ')
						valor26 = ' '
						valor27 = ' '
						if (s.cell(row,22).value) == 'RUC':
							valor26 = '4'
							valor27 = str(s.cell(row,23).value)
							valor27= valor27.split('.', 1)
						
							match = re.match(r'\b[0-9]{11}\b',valor27[0],re.I)
							if not match:
								raise UserError("El Documento RUC Del Tercer Aval debe tener 11 digitos y debe ser un valor Entero("+valor25+")")
						elif (s.cell(row,22).value) == 'DNI':
							valor26 = '1'
							valor27 = str(s.cell(row,23).value)
							valor27= valor27.split('.', 1)

							match = re.match(r'\b[0-9]{8}\b',valor27[0],re.I)
							if not match:
								raise UserError("El Documento DNI del Tercer Aval debe tener 8 digitos y debe ser un valor Entero("+valor25+")")
						valor27n = ' '
						valor27n = valor27[0].rjust(11,' ')
						if valor27n != '           ':
							valor27n = valor27[0].rjust(11,'0')
						direccion_aval_3 = ' '
						direccion_aval_3 = s.cell(row,24).value
						if valor25 != vacio:
							tipo_aval_3 = 'A'
						else:
							tipo_aval_3 = ' '
						direccion_aval_3 = direccion_aval_3.ljust(60,' ')

						#AVAL4
						valor28 = (s.cell(row,25).value)
						valor28 = valor28.ljust(60,' ')
						valor29 = ' '
						valor30 = ' '
						if (s.cell(row,26).value) == 'RUC':
							valor29 = '4'
							valor30 = str(s.cell(row,27).value)
							valor30= valor30.split('.', 1)
						
							match = re.match(r'\b[0-9]{11}\b',valor30[0],re.I)
							if not match:
								raise UserError("El Documento RUC Del Cuarto Aval debe tener 11 digitos y debe ser un valor Entero("+valor28+")")
						elif (s.cell(row,26).value) == 'DNI':
							valor29 = '1'
							valor30 = str(s.cell(row,27).value)
							valor30= valor30.split('.', 1)

							match = re.match(r'\b[0-9]{8}\b',valor30[0],re.I)
							if not match:
								raise UserError("El Documento DNI del Cuarto Aval debe tener 8 digitos y debe ser un valor Entero("+valor28+")")
						valor30n = ' '
						valor30n = valor30[0].rjust(11,' ')
						if valor30n != '           ':
							valor30n = valor30[0].rjust(11,'0')
						direccion_aval_4 = ' '
						direccion_aval_4 = s.cell(row,28).value
						if valor28 != vacio:
							tipo_aval_4 = 'A'
						else:
							tipo_aval_4 = ' '
						direccion_aval_4 = direccion_aval_4.ljust(60,' ')
						
						#AVAL5
						valor31 = (s.cell(row,30).value)
						valor31 = valor31.ljust(60,' ')
						valor32 = ' '
						valor33 = ' '
						if (s.cell(row,31).value) == 'RUC':
							valor32 = '4'
							valor33 = str(s.cell(row,32).value)
							valor33= valor33.split('.', 1)
						
							match = re.match(r'\b[0-9]{11}\b',valor33[0],re.I)
							if not match:
								raise UserError("El Documento RUC Del Quinto Aval debe tener 11 digitos y debe ser un valor Entero("+valor31+")")
						elif (s.cell(row,31).value) == 'DNI':
							valor32 = '1'
							valor33 = str(s.cell(row,32).value)
							valor33= valor33.split('.', 1)

							match = re.match(r'\b[0-9]{8}\b',valor33[0],re.I)
							if not match:
								raise UserError("El Documento DNI del Quinto Aval debe tener 8 digitos y debe ser un valor Entero("+valor31+")")
						valor33n = ' '
						valor33n = valor33[0].rjust(11,' ')
						if valor33n != '           ':
							valor33n = valor33[0].rjust(11,'0')
						direccion_aval_5 = '  '
						direccion_aval_5 = s.cell(row,33).value
						if valor31 != vacio:
							tipo_aval_5 = ' A '
						else:
							tipo_aval_5 = '   '
						direccion_aval_5 = direccion_aval_5.ljust(60,' ')
						salto_linea = ' '
						salto_linea = salto_linea.ljust(13,' ')

						#CONTATENANDO Y ARMANDO EL EL CHAR PARA EL TXT
						pepe = pepe + valor + valor2n+ valor3 + valor4n + valor5n + valor6 + valor7n1+valor8+valor9+valor10+valor11n+valor12+valor13n+valor14n+valor15+valor16+valor17+valor18+valor19+valor20+valor21n+direccion_aval_1+tipo_aval_1+valor22+valor23+valor24n+direccion_aval_2+tipo_aval_2+valor25+valor26+valor27n+direccion_aval_3+tipo_aval_3+valor28+valor29+valor30n+direccion_aval_4+tipo_aval_4+valor31+valor32+valor33n+direccion_aval_5+tipo_aval_5
						
						print(valor)
						# for col in range(s.ncols):
						# 	print(col)
						# 	valor = (s.cell(row, col).value)
						# 	print(valor)
						# 	data_row.append(valor)
		direccion = self.env['convertidor.parameters'].search([])[0].download_url
		with open(direccion + 'protestos_moras.txt','wb') as file:
			pepe2 = pepe.encode('ascii','replace')
			pepe3 = pepe2.replace('?',chr(209))
			file.write(pepe3)