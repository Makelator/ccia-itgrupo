# -*- coding: utf-8 -*-
from openerp.osv import osv
import base64
from odoo import models, fields, api , exceptions
from datetime import datetime, timedelta

class ResPartner(models.Model):
	_inherit = 'res.partner'

	estado_afiliacion = fields.Selection( [('no_afiliado','No Afiliado'),('afiliado','Afiliado'),('proceso','En Proceso de Afiliacion')],'Estado de Afiliacion',default='proceso')