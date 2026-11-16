// adapter-static writes /notes as notes.html, but S3 only matches exact keys.
// Without this, every extensionless path misses and falls through to the error page.
async function handler(event) {
	const request = event.request;
	const uri = request.uri;

	if (uri === '/') {
		request.uri = '/index.html';
	} else if (uri.endsWith('/')) {
		request.uri = uri.slice(0, -1) + '.html';
	} else if (!uri.slice(uri.lastIndexOf('/') + 1).includes('.')) {
		request.uri = uri + '.html';
	}

	return request;
}
