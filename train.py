import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from transformers import AutoTokenizer, get_linear_schedule_with_warmup
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import pandas as pd
import numpy as np
import os
from model import SentimentClassifier, ModelManager
import json
from datetime import datetime

class SentimentDataset(Dataset):
    def __init__(self, texts, labels, tokenizer, max_length=128):
        self.texts = texts
        self.labels = labels
        self.tokenizer = tokenizer
        self.max_length = max_length
    
    def __len__(self):
        return len(self.texts)
    
    def __getitem__(self, idx):
        text = str(self.texts[idx])
        label = self.labels[idx]
        
        encoding = self.tokenizer(
            text,
            truncation=True,
            padding='max_length',
            max_length=self.max_length,
            return_tensors='pt'
        )
        
        return {
            'input_ids': encoding['input_ids'].flatten(),
            'attention_mask': encoding['attention_mask'].flatten(),
            'label': torch.tensor(label, dtype=torch.long)
        }

def load_data(data_path='data/train.csv'):
    if not os.path.exists(data_path):
        print(f"Data file not found at {data_path}. Creating sample data...")
        create_sample_data(data_path)
    
    df = pd.read_csv(data_path)
    texts = df['text'].values
    labels = df['label'].values
    return texts, labels

def create_sample_data(data_path):
    os.makedirs(os.path.dirname(data_path), exist_ok=True)
    sample_data = {
        'text': [
            'I love this product!', 'Amazing quality and fast delivery!', 'Great value for money!',
            'Absolutely fantastic!', 'Best purchase ever!', 'Highly recommend this!',
            'Outstanding service!', 'Exceeded my expectations!', 'Perfect!', 'Wonderful experience!',
            'This is okay, nothing special.', 'Not bad, but could be better.',
            'Average product, meets expectations.', 'Decent enough.', 'It is fine I guess.',
            'Middle of the road.', 'Acceptable quality.', 'Neither good nor bad.', 'So-so product.', 'Fair enough.',
            'Terrible experience, would not recommend.', 'Worst purchase I have ever made.',
            'Poor quality, very disappointed.', 'Complete waste of money.', 'Awful product.',
            'Very unhappy with this.', 'Do not buy this.', 'Horrible experience.', 'Regret buying this.', 'Trash quality.',
        ],
        'label': [2] * 10 + [1] * 10 + [0] * 10
    }
    df = pd.DataFrame(sample_data)
    df.to_csv(data_path, index=False)
    print(f"Sample data created at {data_path}")

def train_model(
    data_path='data/train.csv',
    model_name='distilbert-base-uncased',
    num_epochs=3,
    batch_size=16,
    learning_rate=2e-5,
    model_dir='models',
    output_dir='outputs'
):
    os.makedirs(model_dir, exist_ok=True)
    os.makedirs(output_dir, exist_ok=True)
    
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Using device: {device}")
    
    texts, labels = load_data(data_path)
    train_texts, val_texts, train_labels, val_labels = train_test_split(
        texts, labels, test_size=0.2, random_state=42, stratify=labels
    )
    
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    
    train_dataset = SentimentDataset(train_texts, train_labels, tokenizer)
    val_dataset = SentimentDataset(val_texts, val_labels, tokenizer)
    
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=batch_size)
    
    model = SentimentClassifier(model_name=model_name, num_labels=3)
    model.to(device)
    
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.AdamW(model.parameters(), lr=learning_rate)
    
    total_steps = len(train_loader) * num_epochs
    scheduler = get_linear_schedule_with_warmup(
        optimizer,
        num_warmup_steps=0,
        num_training_steps=total_steps
    )
    
    best_val_acc = 0.0
    training_history = {'train_loss': [], 'val_loss': [], 'val_acc': []}
    
    for epoch in range(num_epochs):
        model.train()
        train_loss = 0.0
        
        for batch in train_loader:
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            labels = batch['label'].to(device)
            
            optimizer.zero_grad()
            outputs = model(input_ids, attention_mask)
            loss = criterion(outputs, labels)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            optimizer.step()
            scheduler.step()
            
            train_loss += loss.item()
        
        model.eval()
        val_loss = 0.0
        val_predictions = []
        val_labels_list = []
        
        with torch.no_grad():
            for batch in val_loader:
                input_ids = batch['input_ids'].to(device)
                attention_mask = batch['attention_mask'].to(device)
                labels = batch['label'].to(device)
                
                outputs = model(input_ids, attention_mask)
                loss = criterion(outputs, labels)
                val_loss += loss.item()
                
                predictions = torch.argmax(outputs, dim=-1)
                val_predictions.extend(predictions.cpu().numpy())
                val_labels_list.extend(labels.cpu().numpy())
        
        val_acc = accuracy_score(val_labels_list, val_predictions)
        avg_train_loss = train_loss / len(train_loader)
        avg_val_loss = val_loss / len(val_loader)
        
        training_history['train_loss'].append(avg_train_loss)
        training_history['val_loss'].append(avg_val_loss)
        training_history['val_acc'].append(val_acc)
        
        print(f"Epoch {epoch+1}/{num_epochs}")
        print(f"Train Loss: {avg_train_loss:.4f}, Val Loss: {avg_val_loss:.4f}, Val Acc: {val_acc:.4f}")
        
        if val_acc > best_val_acc:
            best_val_acc = val_acc
            manager = ModelManager(model_dir)
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            model_path = manager.save_model(model, tokenizer, version=timestamp)
            manager.save_model(model, tokenizer)
            
            report = classification_report(val_labels_list, val_predictions, output_dict=True)
            metrics = {
                'timestamp': timestamp,
                'val_accuracy': val_acc,
                'val_loss': avg_val_loss,
                'train_loss': avg_train_loss,
                'epoch': epoch + 1,
                'classification_report': report
            }
            
            metrics_path = os.path.join(output_dir, f'metrics_{timestamp}.json')
            with open(metrics_path, 'w') as f:
                json.dump(metrics, f, indent=2)
            
            print(f"New best model saved! Accuracy: {val_acc:.4f}")
    
    print(f"\nTraining completed! Best validation accuracy: {best_val_acc:.4f}")
    return model, tokenizer, training_history

if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument('--data_path', type=str, default='data/train.csv')
    parser.add_argument('--num_epochs', type=int, default=3)
    parser.add_argument('--batch_size', type=int, default=16)
    parser.add_argument('--learning_rate', type=float, default=2e-5)
    parser.add_argument('--model_dir', type=str, default='models')
    
    args = parser.parse_args()
    
    train_model(
        data_path=args.data_path,
        num_epochs=args.num_epochs,
        batch_size=args.batch_size,
        learning_rate=args.learning_rate,
        model_dir=args.model_dir
    )


