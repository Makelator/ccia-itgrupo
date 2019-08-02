# -*- encoding: utf-8 -*-
##############################################################################
#
#	OpenERP, Open Source Management Solution
#	Copyright (c) 2012 Andrea Cometa All Rights Reserved.
#					   www.andreacometa.it
#					   openerp@andreacometa.it
#	Copyright (C) 2013 Agile Business Group sagl (<http://www.agilebg.com>)
#
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU Affero General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU Affero General Public License for more details.
#
#	You should have received a copy of the GNU Affero General Public License
#	along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################
# W gli spaghetti code!!!
##############################################################################


from odoo import api, fields, models, _ , exceptions
from odoo import netsvc
import logging
_logger = logging.getLogger(__name__)

class stock_move(models.Model):
	_inherit = 'stock.move'


	@api.one
	def write(self,vals):
		t = super(stock_move,self).write(vals)
		if self.product_id.tracking == 'lot':
			return t

		if self.state == 'done':


			self.env.cr.execute("""
						select Todo.producto, Todo.almacen, Todo.saldo_fisico, quants.cantidad, coalesce(quants_sinresernva.cantidad,0) from (
						select ubicacion as almacen, product_id as producto, pt.categ_id as categoria,
						sum(stock_disponible) as saldo,
						sum(saldo_fisico) as saldo_fisico,
						sum(por_ingresar) as por_ingresar,
						sum(transito) as transito,
						sum(salida_espera) as salida_espera,
						sum(reservas) as reservas,
						sum(previsto) as saldo_virtual,

						replace(replace(array_agg(id_stock_disponible)::text,'{','['),'}',']') as id_stock_disponible,
						replace(replace(array_agg(id_saldo_fisico)::text,'{','['),'}',']') as id_saldo_fisico,
						replace(replace(array_agg(id_por_ingresar)::text,'{','['),'}',']') as id_por_ingresar,
						replace(replace(array_agg(id_transito)::text,'{','['),'}',']') as id_transito,
						replace(replace(array_agg(id_salida_espera)::text,'{','['),'}',']') as id_salida_espera,
						replace(replace(array_agg(id_reservas)::text,'{','['),'}',']') as id_reservas,
						replace(replace(array_agg(id_previsto)::text,'{','['),'}',']') as id_previsto

						from vst_kardex_onlyfisico_total
						inner join product_template pt on pt.id = product_tmpl_id
						where vst_kardex_onlyfisico_total.date >= '2019-01-01'
						and vst_kardex_onlyfisico_total.date <= '2019-12-31'

						and pt.tracking != 'lot'
						group by ubicacion, product_id, pt.categ_id
						order by ubicacion,product_id, pt.categ_id
						) Todo
						left join  (
						select sum(qty) as cantidad,product_id, location_id from stock_quant  group by product_id, location_id
						) quants on quants.product_id = Todo.producto and quants.location_id = Todo.almacen
						left join  (
						select sum(qty) as cantidad,product_id, location_id from stock_quant where reservation_id is not null group by product_id, location_id
						) quants_sinresernva on quants_sinresernva.product_id = Todo.producto and quants_sinresernva.location_id = Todo.almacen
						where Todo.saldo_fisico != quants.cantidad
						 """)
			for i in self.env.cr.fetchall():
				mov = self.env['stock.quant'].search([('product_id','=',i[0]),('location_id','=',i[1]),('reservation_id','=',False)])
				flag = True
				for el in mov:
					if flag:
						flag = False
					else:
						self.env.cr.execute(" delete from stock_quant where id = " + str(el.id) )
				if len(mov)>0:
					mov[0].qty = i[2] - i[4]
				else:
					data= {
						'qty':i[2] - i[4],
						'location_id':i[1],
						'product_id':i[0],
					}
					newquant = self.env['stock.quant'].create(data)

		for mmm in self:
			lineas = self.env['stock.quant'].search([('product_id','=',mmm.product_id.id),('location_id','=',mmm.location_id.id),('reservation_id','=',False)])
			total = 0
			for i in lineas:
				total+= i.qty
			flag = True
			for el in lineas:
				if flag:
					flag = False
				else:
					self.env.cr.execute(" delete from stock_quant where id = " + str(el.id) )
			if len(lineas)>0:
				lineas[0].qty = total



			lineas = self.env['stock.quant'].search([('product_id','=',mmm.product_id.id),('location_id','=',mmm.location_dest_id.id),('reservation_id','=',False)])
			total = 0
			for i in lineas:
				total+= i.qty


			flag = True
			for el in lineas:
				if flag:
					flag = False
				else:
					self.env.cr.execute(" delete from stock_quant where id = " + str(el.id) )
			if len(lineas)>0:
				lineas[0].qty = total

		return t

class stock_picking(models.Model):
	_inherit = 'stock.picking'



	@api.multi
	def unlink(self):
		if self.state=='draft':
			if self.pack_operation_ids:
				for i in self.pack_operation_ids:
					i.unlink()
		return super(stock_picking,self).unlink()


	def has_valuation_moves(self,move):
		return self.env['account.move'].search([
			('ref','=', move.picking_id.name),
			])

	@api.multi
	def anular_alvaran(self):
		self.action_revert_done()
		self.action_cancel()

	@api.multi
	def action_revert_done(self):
		for picking in self:

			for line in picking.move_lines:
				if line.product_id.tracking == 'lot' or line.product_id.tracking == 'serial':
					raise exceptions.ValidationError('No se puede reabrir albaranes con lotes o series.')

				line.origin_returned_move_id = False

				if len(self.has_valuation_moves(line))>1:
					raise osv.except_osv(_('Error'),
						_('Line %s has valuation moves (%s). Remove them first')
						% (line.name, line.picking_id.name))
				#for quant in line.quant_ids:
				#	if quant.reservation_id != False:
				#		quant.with_context({'force_unlink':True}).unlink()
				line.write({'state': 'draft'})
			self.write({'state': 'draft'})
			if not picking.invoice_id:
				pass
				#self.write({'invoice_state': '2binvoiced'})
			wf_service = netsvc.LocalService("workflow")
			# Deleting the existing instance of workflow
			wf_service.trg_delete(self._uid, 'stock.picking', picking.id, self._cr)
			wf_service.trg_create(self._uid, 'stock.picking', picking.id, self._cr)


			for move in picking.move_lines:
				sale_order_lines = move.procurement_id.sale_line_id
				for line in sale_order_lines:
					line.qty_delivered = line._get_delivered_qty()

		for (id,name) in self.name_get():
			import odoo.loglevels as loglevels
			_logger.warning( _("The stock picking '%s' has been set in draft state.") %(name,))
			#message = _("The stock picking '%s' has been set in draft state.") %(name,)
			#self.log(message)

		self.env.cr.execute("""
					select Todo.producto, Todo.almacen, Todo.saldo_fisico, coalesce(quants.cantidad,0), coalesce(quants_sinresernva.cantidad,0) from (
					select ubicacion as almacen, product_id as producto, pt.categ_id as categoria,
					sum(stock_disponible) as saldo,
					sum(saldo_fisico) as saldo_fisico,
					sum(por_ingresar) as por_ingresar,
					sum(transito) as transito,
					sum(salida_espera) as salida_espera,
					sum(reservas) as reservas,
					sum(previsto) as saldo_virtual,

					replace(replace(array_agg(id_stock_disponible)::text,'{','['),'}',']') as id_stock_disponible,
					replace(replace(array_agg(id_saldo_fisico)::text,'{','['),'}',']') as id_saldo_fisico,
					replace(replace(array_agg(id_por_ingresar)::text,'{','['),'}',']') as id_por_ingresar,
					replace(replace(array_agg(id_transito)::text,'{','['),'}',']') as id_transito,
					replace(replace(array_agg(id_salida_espera)::text,'{','['),'}',']') as id_salida_espera,
					replace(replace(array_agg(id_reservas)::text,'{','['),'}',']') as id_reservas,
					replace(replace(array_agg(id_previsto)::text,'{','['),'}',']') as id_previsto

					from vst_kardex_onlyfisico_total
					inner join product_template pt on pt.id = product_tmpl_id
					where vst_kardex_onlyfisico_total.date >= '2019-01-01'
					and vst_kardex_onlyfisico_total.date <= '2019-12-31'

							and pt.tracking != 'lot'
					group by ubicacion, product_id, pt.categ_id
					order by ubicacion,product_id, pt.categ_id
					) Todo
					left join  (
					select sum(qty) as cantidad,product_id, location_id from stock_quant  group by product_id, location_id
					) quants on quants.product_id = Todo.producto and quants.location_id = Todo.almacen
					left join  (
					select sum(qty) as cantidad,product_id, location_id from stock_quant where reservation_id is not null group by product_id, location_id
					) quants_sinresernva on quants_sinresernva.product_id = Todo.producto and quants_sinresernva.location_id = Todo.almacen
					where Todo.saldo_fisico != coalesce(quants.cantidad,0)
					 """)
		for i in self.env.cr.fetchall():
			mov = self.env['stock.quant'].search([('product_id','=',i[0]),('location_id','=',i[1]),('reservation_id','=',False)])
			flag = True
			for el in mov:
				if flag:
					flag = False
				else:
					self.env.cr.execute(" delete from stock_quant where id = " + str(el.id) )
			if len(mov)>0:
				mov[0].qty = i[2] - i[4]
			else:
				data= {
					'qty':i[2] - i[4],
					'location_id':i[1],
					'product_id':i[0],
				}
				newquant = self.env['stock.quant'].create(data)
		return True
