# -*- coding: utf-8 -*-

from odoo import models, fields, api
from odoo import http


class confirm_date_picking(models.TransientModel):
	_name = 'confirm.date.picking'
	pick_id = fields.Many2one('stock.picking')
	date = fields.Date('Fecha del kardex',default=fields.Date.today())

	@api.multi
	def changed_date_pincking(self):
		self.pick_id.fecha_kardex = self.date
		return self.pick_id.with_context({'a':True}).do_new_transfer()

	@api.multi
	def changed_date_pincking_none(self):
		return self.pick_id.with_context({'a':True}).do_new_transfer()


class warehouse_parameters(models.Model):
	_name='warehouse.parameters'


	@api.model_cr
	def init(self):
		self.env.cr.execute('select id from res_users')
		uid = self.env.cr.dictfetchall()
		self.env.cr.execute('select id from warehouse_parameters')
		ids = self.env.cr.fetchall()
		if len(ids) == 0:
			self.env.cr.execute("""INSERT INTO warehouse_parameters (create_uid, name) VALUES (""" + str(uid[0]['id']) + """, 'Parametros Generales');""")

	name = fields.Char(string='Nombre', size=200)
	limit_line_albaran = fields.Integer(string= u'Lìmite de lineas de albaran')
	validar_fecha_albaran = fields.Boolean(string="Validar fecha de albaran")
