# -*- coding: utf-8 -*-
from openerp.osv import osv
import base64
from odoo import models, fields, api , exceptions
from datetime import datetime, timedelta

class ResPartner(models.Model):
	_inherit = 'res.partner'

	#partner_ids_afiliados = fields.One2many('partner.afiliado','partner_id','Cambio de Afiliacion')
	product_service = fields.Many2one('product.product','Servicio Relacionado',domain="[('type', '=','service')]")
	
	_sql_constraints = [('product_service_unique', 'unique(product_service)', 'El servicio solo puede ser asignado a un solo Partner')]