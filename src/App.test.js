import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';

it('renders without crashing', () => {
  const div = document.createElement('div');
  ReactDOM.render(<App />, div);
  ReactDOM.unmountComponentAtNode(div);
});

it('renders blog title', () => {
  const div = document.createElement('div');
  ReactDOM.render(<App />, div);
  expect(div.textContent).toContain('MERN Blog');
  ReactDOM.unmountComponentAtNode(div);
});
