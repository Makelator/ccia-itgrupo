# -*- coding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

import datetime
import logging
import re
import uuid
from urlparse import urljoin
from collections import Counter, OrderedDict
from itertools import product
import base64
from odoo import api, fields, models, tools, SUPERUSER_ID, _
from odoo.exceptions import UserError, ValidationError

from odoo.addons.website.models.website import slug

email_validator = re.compile(r"[^@]+@[^@]+\.[^@]+")
_logger = logging.getLogger(__name__)


class SurveyStage(models.Model):
	"""Stages for Kanban view of surveys"""

	_name = 'survey.stage'
	_description = 'Survey Stage'
	_order = 'sequence,id'

	name = fields.Char(required=True, translate=True)
	sequence = fields.Integer(default=1)
	closed = fields.Boolean(help="If closed, people won't be able to answer to surveys in this column.")
	fold = fields.Boolean(string="Folded in kanban view")

	_sql_constraints = [
		('positive_sequence', 'CHECK(sequence >= 0)', 'Sequence number MUST be a natural')
	]


class Survey(models.Model):
	""" Settings for a multi-page/multi-question survey.
		Each survey can have one or more attached pages, and each page can display
		one or more questions.
	"""
	_inherit = 'survey.survey'

	@api.model
	def get_filter_display_data(self, filters):
		"""Returns data to display current filters
			:param filters: list of dictionary (having: row_id, answer_id)
			:returns list of dict having data to display filters.
		"""
		filter_display_data = []
		if filters:
			Label = self.env['survey.label']
			for current_filter in filters:
				row_id, answer_id = current_filter['row_id'], current_filter['answer_id']
				label = Label.browse(answer_id)
				question = label.question_id
				if row_id == 0:
					labels = label
				else:
					labels = Label.browse([row_id, answer_id])
				filter_display_data.append({'question_text': question.question,
											'labels': labels.mapped('value')})
		return filter_display_data

	@api.model
	def prepare_result(self, question, current_filters=None):
		""" Compute statistical data for questions by counting number of vote per choice on basis of filter """
		current_filters = current_filters if current_filters else []
		result_summary = {}

		# Calculate and return statistics for choice
		if question.type in ['simple_choice', 'multiple_choice']:
			answers = {}
			comments = []
			[answers.update({label.id: {'text': label.value, 'count': 0, 'answer_id': label.id}}) for label in question.labels_ids]
			for input_line in question.user_input_line_ids:
				if input_line.answer_type == 'suggestion' and answers.get(input_line.value_suggested.id) and (not(current_filters) or input_line.user_input_id.id in current_filters):
					answers[input_line.value_suggested.id]['count'] += 1
				if input_line.answer_type == 'text' and (not(current_filters) or input_line.user_input_id.id in current_filters):
					comments.append(input_line)
			result_summary = {'answers': answers.values(), 'comments': comments}

		# Calculate and return statistics for matrix
		if question.type == 'matrix':
			rows = OrderedDict()
			answers = OrderedDict()
			res = dict()
			comments = []
			[rows.update({label.id: label.value}) for label in question.labels_ids_2]
			[answers.update({label.id: label.value}) for label in question.labels_ids]
			for cell in product(rows.keys(), answers.keys()):
				res[cell] = 0
			for input_line in question.user_input_line_ids:
				if input_line.answer_type == 'suggestion' and (not(current_filters) or input_line.user_input_id.id in current_filters) and input_line.value_suggested_row:
					res[(input_line.value_suggested_row.id, input_line.value_suggested.id)] += 1
				if input_line.answer_type == 'text' and (not(current_filters) or input_line.user_input_id.id in current_filters):
					comments.append(input_line)
			result_summary = {'answers': answers, 'rows': rows, 'result': res, 'comments': comments}

		# Calculate and return statistics for free_text, textbox, datetime
		if question.type in ['free_text', 'textbox', 'datetime','attachment']:
			result_summary = []
			for input_line in question.user_input_line_ids:
				if not(current_filters) or input_line.user_input_id.id in current_filters:
					result_summary.append(input_line)

		# Calculate and return statistics for numerical_box
		if question.type == 'numerical_box':
			result_summary = {'input_lines': []}
			all_inputs = []
			for input_line in question.user_input_line_ids:
				if not(current_filters) or input_line.user_input_id.id in current_filters:
					all_inputs.append(input_line.value_number)
					result_summary['input_lines'].append(input_line)
			if all_inputs:
				result_summary.update({'average': round(sum(all_inputs) / len(all_inputs), 2),
									   'max': round(max(all_inputs), 2),
									   'min': round(min(all_inputs), 2),
									   'sum': sum(all_inputs),
									   'most_common': Counter(all_inputs).most_common(5)})
		return result_summary

class SurveyQuestion(models.Model):
	""" Questions that will be asked in a survey.

		Each question can have one of more suggested answers (eg. in case of
		dropdown choices, multi-answer checkboxes, radio buttons...).
	"""

	_inherit = 'survey.question'
	type = fields.Selection([
			('free_text', 'Multiple Lines Text Box'),
			('textbox', 'Single Line Text Box'),
			('numerical_box', 'Numerical Value'),
			('datetime', 'Date and Time'),
			('simple_choice', 'Multiple choice: only one answer'),
			('multiple_choice', 'Multiple choice: multiple answers allowed'),
			('matrix', 'Matrix'),('attachment', 'Attachment')], string='Type of Question', default='free_text', required=True)

	@api.multi
	def validate_attachment(self, post, answer_tag):
		self.ensure_one()
		errors = {}
		return errors




class SurveyUserInputLine(models.Model):
	_inherit = 'survey.user_input_line'

	value_attachment = fields.Binary('Archivo Adjunto')
	value_attachment_name = fields.Char('Nombre del Archivo')
	answer_type = fields.Selection([
        ('text', 'Text'),
        ('number', 'Number'),
        ('date', 'Date'),
        ('free_text', 'Free Text'),
        ('suggestion', 'Suggestion'),
        ('attachment', 'Attachment')], string='Answer Type')

	@api.model
	def save_line_attachment(self, user_input_id, question, post, answer_tag):

		vals = {
			'user_input_id': user_input_id,
			'question_id': question.id,
			'survey_id': question.survey_id.id,
			'skipped': False,
		}
		obj=''
		file_name=False
		print(post)
		if post[answer_tag] == '':
			print('ne')
			vals.update({'answer_type': None, 'skipped': True})
		else:
			file_name=post[answer_tag].filename
			print('lol ',file_name)
			obj = post[answer_tag].read()
			ojb1= base64.b64encode(obj)
			vals.update({'answer_type': 'attachment', 'value_attachment': ojb1, 'value_attachment_name': file_name})
			
		old_uil = self.search([
			('user_input_id', '=', user_input_id),
			('survey_id', '=', question.survey_id.id),
			('question_id', '=', question.id)
		])

		if old_uil:
			old_uil.write(vals)
		else:
			old_uil.create(vals)
		return True

