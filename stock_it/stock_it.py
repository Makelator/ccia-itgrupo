# -*- encoding: utf-8 -*-
from openerp.osv import osv
import base64
from openerp import models, fields, api , exceptions, _

class stock_picking(models.Model):
	_inherit='stock.picking'

	info_disponibilidad = fields.Text('Info',compute="get_check_disponibilidad")
	check_disponibilidad = fields.Boolean('Checkear Disponibilidad',compute="get_check_disponibilidad")

	@api.one
	def get_check_disponibilidad(self):
		if self.state == 'done' or self.location_id.usage!='internal':
			self.check_disponibilidad = True
			self.info_disponibilidad = ""
		else:				
			productos=[-1,-1,-1]

			locacion = -1

			dis_produc = {}
			for i in self.move_lines:
				product_uom_deberia = i.product_id.unidad_kardex if i.product_id.unidad_kardex.id else i.product_id.uom_id
				product_uom_actual = i.product_uom

				productos.append(i.product_id.id)
				if i.product_id.id not in dis_produc:
					dis_produc[i.product_id.id] = ((i.product_uom_qty*product_uom_deberia.factor) / product_uom_actual.factor)
				else:
					dis_produc[i.product_id.id] = dis_produc[i.product_id.id] + ((i.product_uom_qty*product_uom_deberia.factor) / product_uom_actual.factor)

				locacion = i.location_id.id

			self.env.cr.execute("""

					select ubicacion,product_id, sum(stock_disponible), sum(previsto) from vst_kardex_onlyfisico_total
					where product_id in """+str(tuple(productos))+""" and ubicacion = """ +str(locacion)+ """
					group by product_id,ubicacion

			 """)
			txt_tmp = ""



			for i in self.env.cr.fetchall():
				if dis_produc[i[1]] > i[2]:
					product_obj = self.env['product.product'].browse(i[1])						
					product_uom_deberia = product_obj.unidad_kardex if product_obj.unidad_kardex.id else product_obj.uom_id
					txt_tmp += product_obj.name_get()[0][1].ljust(50) + ' pide ' + (str(dis_produc[i[1]]) + ' ' + product_uom_deberia.name).ljust(30)  + ' y dispone ' + str(i[2])  + ' ' + product_uom_deberia.name  + '\n'

			self.info_disponibilidad = txt_tmp
			self.check_disponibilidad = False if txt_tmp != "" else True
			




class stock_move(models.Model):
	_inherit = 'stock.move'


	@api.one
	@api.depends('state', 'product_id', 'product_qty', 'location_id')
	def _compute_product_availability(self):
		if self.state == 'done':

			product_uom_deberia = self.product_id.unidad_kardex if self.product_id.unidad_kardex.id else self.product_id.uom_id
			product_uom_actual = self.product_uom
			self.availability = ((self.product_uom_qty*product_uom_deberia.factor) / product_uom_actual.factor)
		else:
			quants = 0
			if self.product_id.id:

				productos=[-1,-1,-1]

				locacion = -1

				dis_produc = {}
				product_uom_deberia = self.product_id.unidad_kardex if self.product_id.unidad_kardex.id else self.product_id.uom_id
				product_uom_actual = self.product_uom

				productos.append(self.product_id.id)
				if self.product_id.id not in dis_produc:
					dis_produc[self.product_id.id] = ((self.product_uom_qty*product_uom_deberia.factor) / product_uom_actual.factor)
				else:
					dis_produc[self.product_id.id] = dis_produc[self.product_id.id] + ((self.product_uom_qty*product_uom_deberia.factor) / product_uom_actual.factor)


				locacion = self.location_id.id

				self.env.cr.execute("""
					select product_id,ubicacion, sum(stock_disponible) from vst_kardex_onlyfisico_total
					where product_id in """+str(tuple(productos))+""" and ubicacion = """ +str(locacion)+ """
					group by product_id,ubicacion
				 """)
				txt_tmp = ""
				for i in self.env.cr.fetchall():
					quants = i[2]


			product_uom_deberia = self.product_id.unidad_kardex if self.product_id.unidad_kardex.id else self.product_id.uom_id
			product_uom_actual = self.product_uom

			self.availability = min( ((self.product_uom_qty*product_uom_deberia.factor) / product_uom_actual.factor) if product_uom_actual.id and product_uom_actual.factor != 0 else 0 , quants)
