function fn() {
    var config = {
        baseUrl: 'https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api/'
    };

    karate.configure('connectTimeout', 15000);
    karate.configure('readTimeout', 15000);
    karate.configure('logPrettyRequest', true);
    karate.configure('logPrettyResponse', true);

    return config;
}
