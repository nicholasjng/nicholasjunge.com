function serializeQuerystring(querystring) {
	const params = [];
	for (const key in querystring) {
		const entry = querystring[key];
		const values = entry.multiValue || [entry];
		values.forEach((item) => params.push(item.value === '' ? key : key + '=' + item.value));
	}
	return params.length ? '?' + params.join('&') : '';
}

async function handler(event) {
	const request = event.request;
	return {
		statusCode: 301,
		statusDescription: 'Moved Permanently',
		headers: {
			location: {
				value: 'https://nicholasjunge.com' + request.uri + serializeQuerystring(request.querystring)
			}
		}
	};
}
