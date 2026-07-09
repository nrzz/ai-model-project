import os
import unittest
from unittest.mock import MagicMock, patch

import app as flask_app


class TestAPI(unittest.TestCase):
    def setUp(self):
        flask_app.app.config['TESTING'] = True
        self.client = flask_app.app.test_client()
        self._original_reload_token = flask_app.RELOAD_TOKEN
        flask_app.RELOAD_TOKEN = 'test-reload-token'

    def tearDown(self):
        flask_app.RELOAD_TOKEN = self._original_reload_token

    def test_health(self):
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data['status'], 'healthy')
        self.assertIn('model_loaded', data)
        self.assertIn('timestamp', data)

    @patch.object(flask_app.model_manager, 'predict')
    def test_predict_success(self, mock_predict):
        mock_predict.return_value = {
            'prediction': 'positive',
            'confidence': 0.95,
            'probabilities': {
                'negative': 0.01,
                'neutral': 0.04,
                'positive': 0.95,
            },
        }
        with patch.object(flask_app.model_manager, 'model', MagicMock()):
            response = self.client.post('/predict', json={'text': 'Great product!'})

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data['prediction'], 'positive')
        mock_predict.assert_called_once_with('Great product!')

    def test_predict_missing_text(self):
        response = self.client.post('/predict', json={})
        self.assertEqual(response.status_code, 400)
        self.assertIn('error', response.get_json())

    def test_predict_no_model(self):
        with patch.object(flask_app.model_manager, 'model', None):
            response = self.client.post('/predict', json={'text': 'test'})

        self.assertEqual(response.status_code, 503)
        self.assertIn('error', response.get_json())

    def test_reload_without_token(self):
        response = self.client.post('/reload', json={})
        self.assertEqual(response.status_code, 401)

    def test_reload_with_bearer_token(self):
        with patch.object(flask_app.model_manager, 'load_model') as mock_load:
            response = self.client.post(
                '/reload',
                headers={'Authorization': 'Bearer test-reload-token'},
                json={},
            )

        self.assertEqual(response.status_code, 200)
        mock_load.assert_called_once_with(None)

    def test_reload_disabled_when_token_not_configured(self):
        flask_app.RELOAD_TOKEN = None
        response = self.client.post('/reload', json={})
        self.assertEqual(response.status_code, 503)


if __name__ == '__main__':
    unittest.main()
