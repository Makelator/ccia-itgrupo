# -*- encoding: utf-8 -*-
from openerp.osv import osv
import base64
from openerp import models, fields, api , exceptions, _
import csv
from tempfile import TemporaryFile

class stock_quant(models.Model):
	_inherit = 'stock.quant'

	@api.multi
	def _get_latest_move(self):
		if len(self.history_ids)>0:	    		
			latest_move = self.history_ids[0]
			for move in self.history_ids:
				if move.date > latest_move.date:
					latest_move = move
			return latest_move

	@api.multi
	def _price_update(self, newprice):
		# TDE note: use ACLs instead of sudoing everything
		self.sudo().write({'cost': newprice})
		

class import_rest_inv1(models.Model):
	_name = 'import.rest.inv1'

	file_inv = fields.Binary('Archivo con saldos')	
	location_id = fields.Many2one('stock.location',u'Almacén Origen')
	location_dest_id = fields.Many2one('stock.location',u'Almacén Destino')
	date_inv = fields.Date('fecha del inventario')
	picking_type_id = fields.Many2one('stock.picking.type','Tipo de Picking')
	lines = fields.One2many('import.rest.inv.deta1','import_id','Detalle a Importar')

	@api.one
	def load_lines(self):
		for line in self.lines:
			line.unlink()
		if self.file_inv:
			self.env.cr.execute("set client_encoding ='UTF8';")
			line_obj = self.env['import.rest.inv.deta1']
			data = self.read()[0]
			fileobj = TemporaryFile('w+')
			fileobj.write(base64.decodestring(data['file_inv']))
			fileobj.seek(0)
			c=base64.decodestring(data['file_inv'])
			fic = csv.reader(fileobj,delimiter='|',quotechar='"')
			#Creación de líneas en pantalla.
			print fic
			for data in fic:
				if len(data)==3:
					try:
						pro = self.env['product.product'].browse(int(data[0]))
						tmpl = self.env['product.template'].browse(pro.product_tmpl_id.id)
						# print data[0],pro
						if pro:
							vals = {
								'product_id':pro.id,
								'product_qty':float(data[1]),
								'price_unit':float(data[2]),
								'import_id':self.id,
							}
							line_obj.create(vals)
					except Exception as e:
						print data[0]


	@api.one
	def create_inv(self):
		npicking = 0 
		vals_picking = {
			'location_id':self.location_id.id,
			'location_dest_id':self.location_dest_id.id,
			'fecha_kardex':self.date_inv,
			'origin':'Inventario Inicial',
			'date_done':self.date_inv,
			'picking_type_id':self.picking_type_id.id,
			'min_date':self.date_inv,
			'date':self.date_inv,
			'max_date':self.date_inv,
			'name':'Inventario - '+str(npicking)+' - '+self.location_dest_id.name + ' - ' +  str(self.id),
			'einvoice_12':16,
		}
		apickings = []
		picking_id = self.env['stock.picking'].create(vals_picking)
		print 1
		apickings.append(picking_id)
		count=0
		for line in self.lines:
			self.env['stock.move'].create(self._get_move_values(line.product_id,line.price_unit,line.product_qty,self.location_id.id,self.location_dest_id.id,picking_id))
			count=count+1
			if count>79:
				npicking=npicking+1

				#picking_id.do_transfer()
				print picking_id.name
				vals_picking.update({'name':'Inventario - '+str(npicking)+' - '+self.location_dest_id.location_id.name+ ' - ' +  str(self.id)})
				picking_id = self.env['stock.picking'].create(vals_picking)

				print 2
				count =0
				# apickings.append(picking_id)
		# self.env['stock.picking'].do_transfer(apickings)
		#picking_id.do_transfer()
		print 3
		
		print 4
		return True

	def _get_move_values(self, product,price_unit,qty, location_id, location_dest_id,idmain):
		self.ensure_one()
		cadname = 'importado - '+ str(self.id) +str(product.id)

		return {
			'product_id': product.id,
			'product_uom': product.uom_id.id,
			'product_uom_qty': qty,
			# 'product_qty': qty,
			'price_unit':price_unit,
			'date': self.date_inv,
			'location_id': location_id,
			'location_dest_id': location_dest_id,
			'picking_id':idmain.id,
			'origin':'Inventario Inicial',
			'picking_type_id':self.picking_type_id.id,
			'ordered_qty':qty,
			'date_expected':self.date_inv,
			'name': _('INV:') + (idmain.name or ''),
		}



						

				
class import_rest_inv_deta1(models.Model):
	_name = 'import.rest.inv.deta1'

	product_id = fields.Many2one('product.product','Producto')
	product_qty = fields.Float('Cantidad',digits=(20,6))
	price_unit = fields.Float('Precio',digits=(20,6))
	import_id = fields.Many2one('import.rest.inv1','Cabecera importador')
		



class stock_picking(models.Model):
	_inherit = "stock.picking"

	@api.model
	def create(self, vals):
		# TDE FIXME: clean that brol
		
		defaults = self.default_get(['name', 'picking_type_id'])
		if vals.get('name', '/') == '/' and defaults.get('name', '/') == '/' and vals.get('picking_type_id', defaults.get('picking_type_id')):
			vals['name'] = self.env['stock.picking.type'].browse(vals.get('picking_type_id', defaults.get('picking_type_id'))).sequence_id.next_by_id()

		# TDE FIXME: what ?
		# As the on_change in one2many list is WIP, we will overwrite the locations on the stock moves here
		# As it is a create the format will be a list of (0, 0, dict)
		if vals.get('move_lines') and vals.get('location_id') and vals.get('location_dest_id'):
			for move in vals['move_lines']:
				if len(move) == 3:
					move[2]['location_id'] = vals['location_id']
					move[2]['location_dest_id'] = vals['location_dest_id']
		
		if 'origin' in vals:
			if vals['origin']=='Inventario Inicial':
				if 'message_follower_ids' in vals:
					vals['message_follower_ids']= False
		return super(stock_picking, self).create(vals)
