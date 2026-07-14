import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api/api';

const Home = () => {
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    const fetchMessage = async () => {
      try {
        const response = await api.get('/hello');
        setMessage(response.data.message);
      } catch (err) {
        setError('Failed to fetch message');
      }
    };

    fetchMessage();
  }, []);

  const handleLogout = () => {
    localStorage.removeItem('token');
    navigate('/');
  };

  return (
    <div className="home-container">
      <div className="home-box">
        <h1>Home</h1>
        {message && <p className="message">{message}</p>}
        {error && <p className="error">{error}</p>}
        <button onClick={handleLogout}>Logout modified for test code review</button>
      </div>
    </div>
  );
};

export default Home;
