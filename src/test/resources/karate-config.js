function fn() {
    var config = {
        baseUrl: 'https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api/'
    };

    // Timeouts de 60s para tolerar el arranque en frío (cold start) de servidores Render gratuitos
    karate.configure('connectTimeout', 60000);
    karate.configure('readTimeout', 60000);
    karate.configure('logPrettyRequest', true);
    karate.configure('logPrettyResponse', true);

    return config;
}
