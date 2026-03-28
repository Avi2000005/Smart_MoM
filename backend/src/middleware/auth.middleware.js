const jwt = require("jsonwebtoken");

function authMiddleware(req,res,next){

  try{

    let token;

    // token from Authorization header
    const authHeader = req.headers.authorization;

    if(authHeader){
      token = authHeader.split(" ")[1];
    }

    // token from query (used for PDF export)
    if(!token && req.query.token){
      token = req.query.token;
    }

    if(!token){
      return res.status(401).json({
        message:"Unauthorized"
      });
    }

    const decoded = jwt.verify(token,process.env.JWT_SECRET);

    req.userId = decoded.id;

    next();

  }catch(err){

    return res.status(401).json({
      message:"Invalid token"
    });

  }

}

module.exports = authMiddleware;