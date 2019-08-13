# -*- coding: utf-8 -*-


from odoo import http

from odoo import api, fields, models, _

class notarias_modelo(models.Model):
	_name = 'notarias.modelo'

	name = fields.Char('Nombre Notaria')
	codigo = fields.Char('Codigo de Notaria')

	_sql_constraints = [('codigo_unique', 'unique(codigo)', 'El codigo ya esta siendo usado para otra notaria'),('name_unique', 'unique(name)', 'El Nombre ya esta siendo usado para otra notaria')]

