import unittest
import torch
from model import SentimentClassifier, ModelManager

class TestModel(unittest.TestCase):
    def test_model_initialization(self):
        model = SentimentClassifier()
        self.assertIsNotNone(model)
    
    def test_model_forward(self):
        model = SentimentClassifier()
        tokenizer = ModelManager().tokenizer
        if tokenizer is None:
            from transformers import AutoTokenizer
            tokenizer = AutoTokenizer.from_pretrained('distilbert-base-uncased')
        
        text = "This is a test"
        encoding = tokenizer(text, return_tensors='pt', padding=True, truncation=True)
        
        with torch.no_grad():
            output = model(encoding['input_ids'], encoding['attention_mask'])
            self.assertEqual(output.shape[0], 1)
            self.assertEqual(output.shape[1], 3)

if __name__ == '__main__':
    unittest.main()

