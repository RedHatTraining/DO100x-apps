const axios = require('axios');

const NAME_GENERATOR_URL = 'http://name-generator';
const DEFAULT_NAME = 'Susan';

const getNameFromExternalService = () => {
    return axios.get(`${NAME_GENERATOR_URL}/random-name`, {timeout: 200})
};

const getName = async () => {
  try {
    const response = await getNameFromExternalService();
    return Promise.resolve(response.data.name);
  } catch(e) {
    return Promise.resolve(DEFAULT_NAME);
  }
};

const getRandomNumber = () => {
  return Math.floor(Math.random() * 1000);
};

const composeEmailWithName = (name) => {
  return `${name}${getRandomNumber()}@host`
};

const generateEmail = async () => {
  const name = await getName();

  return Promise.resolve({
    email: composeEmailWithName(name)
  });
};

exports.generateEmail = generateEmail;