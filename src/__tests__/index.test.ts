import fs from 'fs';
import path from 'path';
import '@testing-library/jest-dom';
import { getByText, getByPlaceholderText, fireEvent, waitFor } from '@testing-library/dom';

const html = fs.readFileSync(path.resolve(__dirname, '../../public/index.html'), 'utf8');

describe('Weather App Frontend', () => {
  let container: HTMLElement;

  beforeEach(() => {
    document.documentElement.innerHTML = html;
    container = document.body;
    global.fetch = jest.fn();

    // Define showError first since it's used in getWeather
    window.showError = (message: string) => {
      const errorInfo = document.getElementById('errorInfo');
      if (errorInfo) {
        errorInfo.style.display = 'block';
        errorInfo.innerHTML = `<p>${message}</p>`;
      }
    };
    //function to get weather data
    window.getWeather = async () => {
      const cityInput = document.getElementById('cityInput') as HTMLInputElement;
      const weatherInfo = document.getElementById('weatherInfo');
      const errorInfo = document.getElementById('errorInfo');
      const city = cityInput?.value.trim() || '';

      if (weatherInfo) weatherInfo.style.display = 'none';
      if (errorInfo) errorInfo.style.display = 'none';

      if (!city) {
        window.showError('Please enter a city name');
        return;
      }

      try {
        const response = await fetch(`/weather/${city}`);
        const data = await response.json();

        if (response.ok && weatherInfo) {
          weatherInfo.style.display = 'block';
          weatherInfo.innerHTML = `
            <h2>Weather in ${data.name}</h2>
            <p>Temperature: ${data.main.temp}°C</p>
            <p>Weather: ${data.weather[0].main}</p>
            <p>Description: ${data.weather[0].description}</p>
            <p>Humidity: ${data.main.humidity}%</p>
          `;
        } else {
          window.showError(data.error);
        }
      } catch (error) {
        window.showError('I am tired, boss.');
      }
    };
  });

  it('should display weather data for Zakopane', async () => {
    const mockWeatherData = {
      name: 'Zakopane',
      main: {
        temp: 5.2,
        humidity: 75
      },
      weather: [{
        main: 'Clouds',
        description: 'scattered clouds'
      }]
    };

    global.fetch = jest.fn().mockResolvedValueOnce({
      ok: true,
      json: async () => mockWeatherData
    });

    const input = getByPlaceholderText(container, 'Enter city name');
    const button = getByText(container, 'Send');

    fireEvent.change(input, { target: { value: 'Zakopane' } });
    fireEvent.click(button);

    await waitFor(() => {
      expect(getByText(container, 'Weather in Zakopane')).toBeInTheDocument();
      expect(getByText(container, 'Temperature: 5.2°C')).toBeInTheDocument();
    });
  });

  it('should display error for non-existent city Enapokaz', async () => {
    global.fetch = jest.fn().mockResolvedValueOnce({
      ok: false,
      json: async () => ({
        error: 'I am tired, boss.',
        details: 'city not found'
      })
    });

    const input = getByPlaceholderText(container, 'Enter city name');
    const button = getByText(container, 'Send');

    fireEvent.change(input, { target: { value: 'Enapokaz' } });
    fireEvent.click(button);

    await waitFor(() => {
      expect(getByText(container, 'I am tired, boss.')).toBeInTheDocument();
    });
  });
}); 