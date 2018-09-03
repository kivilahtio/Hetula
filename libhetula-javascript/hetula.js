'use strict';

/**
 * @version 0.0.2
 *
 * Hetula Client implementation
 * for more documentation about possible request-response pairs, see the Swagger-UI in
 * @see <hetula-hostname>/api/v1/doc/
 *
 * Repository
 * @see {@link https://github.com/kivilahtio/Hetula}
 *
 * @license GPL3+
 * @copyright National Library of Finland
 */
class Hetula {
  constructor(baseUrl) {
    /** Hetula server address */
    this.baseUrl = baseUrl;
    /** User-agent used to drive the HTTP-requests. Using axios */
    this.browser = axios.create({
      withCredentials: true,
      baseURL: baseUrl+'/api/v1/',
      xsrfHeaderName: 'x-csrf-token', //For some reason this is broken. CSRF is manually added during login.
    })
  }

  /**
   * Authenticate to Hetula
   *
   * @param {String} username
   * @param {String} password
   * @param {String} organization
   * @returns {Promise} axios-response to a request, either a response-object on success, or a error-object on failure
   */
  login(username, password, organization) {
    return this.browser.post("auth", {
      username,
      password,
      organization,
    }).then((response) => {
      if (response.headers['x-csrf-token']) {
        this.browser.defaults.headers.common['x-csrf-token'] = response.headers['x-csrf-token']
      }
      else {
        return Promise.reject({
          error: "Header X-CSRF-Token is missing from response?",
          response,
        });
      }
      return response; //Allow chaining Promise-handlers with the result
    })
  }

  /**
   * Check if the current user agent is authenticated
   * @returns {Promise} axios-response to a request, either a response-object on success, or a error-object on failure
   */
  loggedIn() {
    return this.browser.get("auth")
  }

  /**
   *
   * @param {String} organization
   * @returns {Promise} axios-response to a request, either a response-object on success, or a error-object on failure
   */
  organizationAdd(name) {
    return this.browser.post("organizations", {
      name
    })
  }

  /**
   *
   * @param {String} ssn
   * @returns {Promise} axios-response to a request, either a response-object on success, or a error-object on failure
   */
  ssnAdd(ssn) {
    return this.browser.post("ssns", {
      ssn
    });
  }
}
