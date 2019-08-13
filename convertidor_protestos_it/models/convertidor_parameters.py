# -*- coding: utf-8 -*-


from odoo import http

from odoo import api, fields, models, _

class convertidor_parameters(models.Model):
	_name = 'convertidor.parameters'

	@api.model_cr
	def init(self):
		self.env.cr.execute('select id from res_users')
		uid = self.env.cr.dictfetchall()
		print 'uid', uid
		print 'uid0', uid[0]['id']
		self.env.cr.execute('select id from convertidor_parameters')
		ids = self.env.cr.fetchall()
		
		print 'ids', ids
		
		if len(ids) == 0:
			self.env.cr.execute("""INSERT INTO convertidor_parameters (create_uid, name) VALUES (""" + str(uid[0]['id']) + """, 'Parametros Protestos');""")

	name = fields.Char('Parametros Protestos',size=50, default='Parametros Generales')
	download_directory = fields.Char('Directorio de Descarga/Completa')
	download_url = fields.Char('Directorio de Descarga/Url')