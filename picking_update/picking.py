#-*- coding: utf-8 -*-

from odoo import models, fields, api
import dateutil.parser

class main_parameter_update(models.Model):
	_inherit='main.parameter'

	picking_parameter_in = fields.Many2one('stock.picking.type','Tipo de Operacion Consumo')
	picking_parameter_out = fields.Many2one('stock.picking.type','Tipo de Operacion Ingreso')

class mrp_production(models.Model):
	_inherit = 'mrp.production'
	
	picking_salida = fields.Many2one('stock.picking.type','Tipo de Operacion Consumo',required=True)
	picking_ingreso = fields.Many2one('stock.picking.type','Tipo de Operacion Ingreso',required=True)


	
	@api.model
	def default_get(self, field_list):
		res = super(mrp_production, self).default_get(field_list)
		res.update({
			'picking_salida': self.env['main.parameter'].search([])[0].picking_parameter_in.id,
			'picking_ingreso': self.env['main.parameter'].search([])[0].picking_parameter_out.id,
			})
		return res



class MrpProductProduce(models.TransientModel):
	_inherit = "mrp.product.produce"

	@api.multi
	def do_produce(self):
		super(MrpProductProduce,self).do_produce()

		mrp_prod = self.env['mrp.production'].search([('id','=',self.production_id.id)])

		picking_in = mrp_prod.picking_salida
		picking_out = mrp_prod.picking_ingreso

		#Materiales Consumidos
		vals = {
			'location_id' : picking_in.default_location_src_id.id,
			'location_dest_id' : picking_in.default_location_dest_id.id,
			'move_type' : 'one',
			'picking_type_id' : picking_in.id,
			'fecha_kardex':fields.date.today(),
			'origin': mrp_prod.name
			}

		pick_in = self.env['stock.picking'].create(vals)

		moves = self.production_id.move_raw_ids
		for move in moves.filtered(lambda x: x.product_id.tracking == 'none' and x.state not in ('done', 'cancel')):
			move.picking_id = pick_in.id 


		#Productos Finales
		vals2 = {
			'location_id' : picking_out.default_location_src_id.id,
			'location_dest_id' : picking_out.default_location_dest_id.id,
			'move_type' : 'one',
			'fecha_kardex':fields.date.today(),
			'picking_type_id' : picking_out.id,
			'origin': mrp_prod.name
		}

		pick_out = self.env['stock.picking'].create(vals2)

		moves = self.production_id.move_finished_ids
		for i_m in moves:
			if i_m.picking_id.id:
				pass
			else:
				i_m.picking_id = pick_out.id 
		# move in moves:
		# 	move.picking_id = pick_out.id 