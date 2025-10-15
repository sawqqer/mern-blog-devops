const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 8000;

// Middleware
app.use(cors());
app.use(express.json());

// Mock data
const articles = {
  'learn-react': { upvotes: 42, comments: [
    { username: 'John Doe', text: 'Great article!' },
    { username: 'Jane Smith', text: 'Very helpful, thanks!' }
  ]},
  'learn-node': { upvotes: 15, comments: [
    { username: 'Mike Johnson', text: 'Excellent tutorial' }
  ]},
  'my-thoughts-on-resumes': { upvotes: 8, comments: [] }
};

// Routes
app.get('/api/articles/:name', (req, res) => {
  const { name } = req.params;
  const article = articles[name] || { upvotes: 0, comments: [] };
  res.json(article);
});

app.post('/api/articles/:name/upvote', (req, res) => {
  const { name } = req.params;
  if (articles[name]) {
    articles[name].upvotes += 1;
    res.json(articles[name]);
  } else {
    articles[name] = { upvotes: 1, comments: [] };
    res.json(articles[name]);
  }
});

app.post('/api/articles/:name/add-comment', (req, res) => {
  const { name } = req.params;
  const { username, text } = req.body;
  
  if (!articles[name]) {
    articles[name] = { upvotes: 0, comments: [] };
  }
  
  articles[name].comments.push({ username, text });
  res.json(articles[name]);
});

app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`🚀 Backend API server running on http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
});
