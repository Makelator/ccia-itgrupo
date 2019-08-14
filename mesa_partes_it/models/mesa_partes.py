# -*- coding: utf-8 -*-
from odoo.tools.misc import DEFAULT_SERVER_DATETIME_FORMAT
from openerp.exceptions import Warning
import time
from odoo.exceptions import UserError
import odoo.addons.decimal_precision as dp
from openerp.osv import osv
import base64
from odoo import models, fields, api
from datetime import datetime, timedelta
import codecs
values = {}

import datetime

class MesaPartes(models.Model):
	_name = 'mesa.partes'
	_inherit = ['mail.thread']
	_rec_name='id'

	name = fields.Char(string="nombre")
	codigo_ref = fields.Char(string="Codigo")
	remitente = fields.Char(string="Remitente")
	state = fields.Selection([('recibido', 'Recibido'),
								('revisado', 'Revisado')],
								string='Estado', default='recibido',track_visibility='onchange')
	nro_registro = fields.Integer(string='Numero de Registro')
	tipo_documento = fields.Many2one('tipo.documento.mesa', string="Tipo de Documento")
	remitente = fields.Char(string="Remitente")
	destinatario = fields.Char(string="Destinatario")
	descripcion = fields.Text(string="Descripcion")
	observaciones = fields.Text(string="Observaciones")
	fecha = fields.Datetime(string="Fecha")


	@api.model
	def default_get(self, fields):
		res = super(MesaPartes, self).default_get(fields)
		fecha_hoy = str(datetime.datetime.now())[:10]
		res.update({'fecha':fecha_hoy})
		return res

	@api.model
	def create(self,vals):
	# Override the original create function for the res.partner model
		year=datetime.date.today().strftime("%Y")
		current_year=str(year)
		id_seq = self.env['ir.sequence'].search([('name','=','MesaPartes Seq '+current_year+'')])
		if len(id_seq)>0:
			id_seq = id_seq[0]
		else:
			id_seq = self.env['ir.sequence'].create({'name':'MesaPartes Seq '+current_year+'','implementation':'standard','active':True,'prefix':'00','padding':4,'number_increment':1,'number_next_actual' :0})
		vals['codigo_ref'] = id_seq.next_by_id()
		print(vals['codigo_ref'])
		record = super(MesaPartes, self).create(vals)
		return record

	@api.multi
	def revisar_button(self):
		if self.descripcion and self.observaciones:
			self.state='revisado'
		else:
			raise UserError("Debe Llenar los campos de descripcion y observaciones para continuar")
		


class TipoDocumentoMesa(models.Model):
	_name = 'tipo.documento.mesa'
	_rec_name = 'name'
	name = fields.Char(string="Nombre del Tipo de Documento")
