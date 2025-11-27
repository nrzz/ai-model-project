import torch
import torch.nn as nn
from transformers import AutoTokenizer, AutoModel
import os

class SentimentClassifier(nn.Module):
    def __init__(self, model_name='distilbert-base-uncased', num_labels=3):
        super(SentimentClassifier, self).__init__()
        self.bert = AutoModel.from_pretrained(model_name)
        self.dropout = nn.Dropout(0.3)
        self.classifier = nn.Linear(self.bert.config.hidden_size, num_labels)
        
    def forward(self, input_ids, attention_mask):
        outputs = self.bert(input_ids=input_ids, attention_mask=attention_mask)
        pooled_output = outputs.last_hidden_state[:, 0]
        output = self.dropout(pooled_output)
        return self.classifier(output)

class ModelManager:
    def __init__(self, model_dir='models'):
        self.model_dir = model_dir
        os.makedirs(model_dir, exist_ok=True)
        self.model = None
        self.tokenizer = None
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        
    def load_model(self, model_path=None):
        if model_path is None:
            model_path = os.path.join(self.model_dir, 'best_model.pt')
        
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model not found at {model_path}")
        
        self.tokenizer = AutoTokenizer.from_pretrained('distilbert-base-uncased')
        self.model = SentimentClassifier()
        self.model.load_state_dict(torch.load(model_path, map_location=self.device))
        self.model.to(self.device)
        self.model.eval()
        return self.model, self.tokenizer
    
    def save_model(self, model, tokenizer, version=None):
        if version:
            model_path = os.path.join(self.model_dir, f'model_v{version}.pt')
        else:
            model_path = os.path.join(self.model_dir, 'best_model.pt')
        
        torch.save(model.state_dict(), model_path)
        print(f"Model saved to {model_path}")
        return model_path
    
    def predict(self, text):
        if self.model is None or self.tokenizer is None:
            raise ValueError("Model not loaded. Call load_model() first.")
        
        encoding = self.tokenizer(
            text,
            truncation=True,
            padding=True,
            max_length=128,
            return_tensors='pt'
        )
        
        input_ids = encoding['input_ids'].to(self.device)
        attention_mask = encoding['attention_mask'].to(self.device)
        
        with torch.no_grad():
            outputs = self.model(input_ids, attention_mask)
            predictions = torch.nn.functional.softmax(outputs, dim=-1)
            predicted_class = torch.argmax(predictions, dim=-1).item()
            confidence = predictions[0][predicted_class].item()
        
        labels = ['negative', 'neutral', 'positive']
        return {
            'prediction': labels[predicted_class],
            'confidence': confidence,
            'probabilities': {
                label: prob.item() for label, prob in zip(labels, predictions[0])
            }
        }

