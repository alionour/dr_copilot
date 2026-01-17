import '../domain/models/clinical_report_template.dart';

class ClinicalReportTemplatesData {
  static const List<ClinicalReportTemplate> templates = [
    ClinicalReportTemplate(
      id: 'initial_evaluation',
      name: 'Initial Evaluation',
      content: [
        {
          "insert": "Chief Complaint\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "History of Present Illness\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Past Medical History\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Medications\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Allergies\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Physical Exam\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Assessment\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Plan\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
      ],
    ),
    ClinicalReportTemplate(
      id: 'follow_up_note',
      name: 'Follow-up Note',
      content: [
        {
          "insert": "Interval History\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Review of Systems\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Physical Exam Findings\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Assessment\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Plan\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
      ],
    ),
    ClinicalReportTemplate(
      id: 'discharge_summary',
      name: 'Discharge Summary',
      content: [
        {
          "insert": "Date of Admission\n",
          "attributes": {"bold": true},
        },
        {"insert": "\n"},
        {
          "insert": "Date of Discharge\n",
          "attributes": {"bold": true},
        },
        {"insert": "\n"},
        {
          "insert": "Admitting Diagnosis\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Discharge Diagnosis\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Hospital Course\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Discharge Medications\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Discharge Instructions\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Follow-up Plan\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
      ],
    ),
    ClinicalReportTemplate(
      id: 'soap_note',
      name: 'SOAP Note',
      content: [
        {
          "insert": "Subjective\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Objective\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Assessment\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
        {
          "insert": "Plan\n",
          "attributes": {"bold": true, "header": 2},
        },
        {"insert": "\n"},
      ],
    ),
  ];
}

