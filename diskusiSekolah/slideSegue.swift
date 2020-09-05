//
//  slideSegue.swift
//  diskusiSekolah
//
//  Created by Daniel Anadi Bagaskara on 05/05/20.
//  Copyright © 2020 Daniel Anadi Bagaskara. All rights reserved.
//

import UIKit

class slideSegue: UIStoryboardSegue {
    override func perform()
        {
            let src = self.source as UIViewController
            let dst = self.destination as UIViewController
            
            src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
            dst.view.transform = CGAffineTransform(translationX: src.view.frame.size.width, y: 0)

            UIView.animate(withDuration: 0.25,
                delay: 0.0,
                animations: {
                    dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
                },
                completion: { finished in
                    src.present(dst, animated: false, completion: nil)
                }
            )
        }
    }

    class unwindSlideSegue: UIStoryboardSegue {
        
        override func perform()
        {
            let src = self.source as UIViewController
            let dst = self.destination as UIViewController
            
            src.view.superview?.insertSubview(dst.view, belowSubview: src.view)
            src.view.transform = CGAffineTransform(translationX: 0, y: 0)
            
            UIView.animate(withDuration: 0.25,
                delay: 0.0,
                animations: {
                    src.view.transform = CGAffineTransform(translationX: src.view.frame.size.width, y: 0)
                },
                completion: { finished in
                    src.dismiss(animated: false, completion: nil)
                }
            )
        }
    }
